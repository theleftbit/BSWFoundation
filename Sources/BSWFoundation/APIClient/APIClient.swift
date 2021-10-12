//
//  Created by Pierluigi Cifani on 02/03/2018.
//  Copyright © 2018 TheLeftBit. All rights reserved.
//

import Foundation
import Task
import Deferred
#if canImport(UIKit)
import UIKit
#endif

public protocol APIClientNetworkFetcher {
    func fetchData(with urlRequest: URLRequest, urlCache: URLCache?) -> Task<APIClient.Response>
    func uploadFile(with urlRequest: URLRequest, fileURL: URL) -> Task<APIClient.Response>
}

public protocol APIClientDelegate: AnyObject {
    func apiClientDidReceiveUnauthorized(forRequest atPath: String, apiClient: APIClient) -> Task<()>?
    func apiClientDidReceiveError(_ error: Error, forRequest atPath: String, apiClient: APIClient)
}

public extension APIClientDelegate {
    func apiClientDidReceiveError(_ error: Error, forRequest atPath: String, apiClient: APIClient) { }
}

open class APIClient {

    open weak var delegate: APIClientDelegate?
    open var loggingConfiguration = LoggingConfiguration.default
    open var delegateQueue = DispatchQueue.main
    private var router: Router
    private let workerQueue: OperationQueue
    private let networkFetcher: APIClientNetworkFetcher
    private let sessionDelegate: SessionDelegate
    open var mapError: (Swift.Error) -> (Swift.Error) = { $0 }
    open var customizeRequest: (URLRequest) -> (URLRequest) = { $0 }
    private let cache: URLCache

    public static func backgroundClient(environment: Environment) -> APIClient {
        let session = URLSession(configuration: .background(withIdentifier: "\(Bundle.main.displayName)-APIClient"))
        return APIClient(environment: environment, networkFetcher: session)
    }

    public init(environment: Environment, networkFetcher: APIClientNetworkFetcher? = nil) {
        let sessionDelegate = SessionDelegate(environment: environment)
        let queue = queueForSubmodule("APIClient", qualityOfService: .userInitiated)
        self.router = Router(environment: environment)
        let cache: URLCache  = {
            let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let diskCacheURL = cachesURL.appendingPathComponent("APIClientCache")
            if #available(iOS 13.0, *) {
                return URLCache(memoryCapacity: 1_000_000, diskCapacity: 10_000_000, directory: diskCacheURL)
            } else {
                return URLCache.init()
            }
        }()
        self.networkFetcher = networkFetcher ?? URLSession(configuration: {
            let config = URLSessionConfiguration.default
            config.urlCache = cache
            return config
        }(), delegate: sessionDelegate, delegateQueue: queue)
        self.cache = cache
        self.workerQueue = queue
        self.sessionDelegate = sessionDelegate
    }

    public func perform<T: Decodable>(_ request: Request<T>) -> Task<T> {
        let task: Task<T> =
            createURLRequest(endpoint: request.endpoint)
            .andThen(upon: workerQueue) { self.customizeNetworkRequest(networkRequest: $0) }
            .andThen(upon: workerQueue) { self.sendNetworkRequest($0, cacheResponse: request.endpoint.cacheResponse) }
            .andThen(upon: workerQueue) { request.performUserValidator(onResponse: $0, queue: self.delegateQueue) }
            .andThen(upon: workerQueue) { self.validateResponse($0) }
            .andThen(upon: workerQueue) { self.parseResponseData($0) }
            .recover(upon: workerQueue) { throw self.mapError($0) }
        return task.fallback(upon: delegateQueue) { (error) in
            return self.attemptToRecoverFrom(error: error, request: request)
        }
    }

    public func performSimpleRequest(forEndpoint endpoint: Endpoint) -> Task<APIClient.Response> {
        createURLRequest(endpoint: endpoint)
            .andThen(upon: workerQueue) {
                self.customizeNetworkRequest(networkRequest: $0)
            }
            .andThen(upon: workerQueue) {
                self.sendNetworkRequest($0, cacheResponse: endpoint.cacheResponse)
            }
    }
        
    public var currentEnvironment: Environment {
        return self.router.environment
    }
}

extension APIClient {

    public enum Error: Swift.Error {
        case malformedURL
        case malformedParameters
        case malformedResponse
        case encodingRequestFailed
        case multipartEncodingFailed(reason: MultipartFormFailureReason)
        case malformedJSONResponse(Swift.Error)
        case failureStatusCode(Int, Data?)
        case requestCanceled
        case unknownError
    }

    public struct LoggingConfiguration {
        
        public let requestBehaviour: Behavior
        public let responseBehaviour: Behavior
        
        public init(requestBehaviour: Behavior, responseBehaviour: Behavior) {
            self.requestBehaviour = requestBehaviour
            self.responseBehaviour = responseBehaviour
        }
        
        public static var `default` = LoggingConfiguration(requestBehaviour: .none, responseBehaviour: .onlyFailing)
        public enum Behavior {
            case none
            case all
            case onlyFailing
        }
    }
        
    public struct Response {
        public let data: Data
        public let httpResponse: HTTPURLResponse
        
        public init(data: Data, httpResponse: HTTPURLResponse) {
            self.data = data
            self.httpResponse = httpResponse
        }
    }
}

// MARK: Private

private extension APIClient {
    
    typealias NetworkRequest = (request: URLRequest, fileURL: URL?)
    
    func customizeNetworkRequest(networkRequest: NetworkRequest) -> Task<NetworkRequest> {
        return Task.async(upon: self.delegateQueue, onCancel: APIClient.Error.requestCanceled) { () in
            return (self.customizeRequest(networkRequest.request), networkRequest.fileURL)
        }
    }
    
    func sendNetworkRequest(_ networkRequest: NetworkRequest, cacheResponse: Bool) -> Task<APIClient.Response> {
        defer { logRequest(request: networkRequest.request) }
        if let fileURL = networkRequest.fileURL {
            let task = self.networkFetcher.uploadFile(with: networkRequest.request, fileURL: fileURL)
            task.upon(self.workerQueue) { (_) in
                self.deleteFileAtPath(fileURL: fileURL)
            }
            return task
        } else {
            return self.networkFetcher.fetchData(with: networkRequest.request, urlCache: cacheResponse ? cache :  nil)
        }
    }

    func validateResponse(_ response: Response) -> Task<Data> {
        defer { logResponse(response)}
        switch response.httpResponse.statusCode {
        case (200..<300):
            return .init(success: response.data)
        default:
            let apiError = APIClient.Error.failureStatusCode(response.httpResponse.statusCode, response.data)
            
            if let path = response.httpResponse.url?.path {
                delegateQueue.async {
                    self.delegate?.apiClientDidReceiveError(apiError, forRequest: path, apiClient: self)
                }
            }

            return .init(failure: apiError)
        }
    }

    func parseResponseData<T: Decodable>(_ data: Data) -> Task<T> {
        return JSONParser.parseData(data)
    }

    func attemptToRecoverFrom<T: Decodable>(error: Swift.Error, request: Request<T>) -> Task<T> {
        guard error.is401,
            request.shouldRetryIfUnauthorized,
            let newSignatureTask = self.delegate?.apiClientDidReceiveUnauthorized(forRequest: request.endpoint.path, apiClient: self) else {
            return Task(failure: error)
        }
        let mutatedRequest = Request<T>(
            endpoint: request.endpoint,
            shouldRetryIfUnauthorized: false,
            validator: request.validator
        )
        return newSignatureTask.andThen(upon: workerQueue) { _ in
            return self.perform(mutatedRequest)
        }
    }

    func createURLRequest(endpoint: Endpoint) -> Task<(URLRequest, URL?)> {
        let deferred = Deferred<Task<(URLRequest, URL?)>.Result>()
        let operation = BlockOperation {
            do {
                let request = try self.router.urlRequest(forEndpoint: endpoint)
                deferred.fill(with: .success(request))
            } catch let error {
                deferred.fill(with: .failure(error))
            }
        }
        workerQueue.addOperation(operation)
        return Task(deferred, uponCancel: { [weak operation] in
            operation?.cancel()
        })
    }

    @discardableResult
    func deleteFileAtPath(fileURL: URL) -> Task<()> {
        let deferred = Deferred<Task<()>.Result>()
        FileManagerWrapper.shared.perform { fileManager in
            do {
                try fileManager.removeItem(at: fileURL)
                deferred.succeed(with: ())
            } catch let error {
                deferred.fail(with: error)
            }
        }
        return Task(deferred)
    }

    /// Proxy object to do all our URLSessionDelegate work
    class SessionDelegate: NSObject, URLSessionDelegate {
        
        let environment: Environment
        
        init(environment: Environment) {
            self.environment = environment
            super.init()
        }
        
        public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if self.environment.shouldAllowInsecureConnections {
                completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
}

import os.log

//MARK: Logging

private extension APIClient {
    private func logRequest(request: URLRequest) {
        switch loggingConfiguration.requestBehaviour {
        case .all:
            let customLog = OSLog(subsystem: submoduleName("APIClient"), category: "APIClient.Request")
            let httpMethod = request.httpMethod ?? "GET"
            let path = request.url?.path ?? ""
            os_log("Method: %{public}@ Path: %{public}@", log: customLog, type: .debug, httpMethod, path)
            if let data = request.httpBody, let prettyString = String(data: data, encoding: .utf8) {
                os_log("Body: %{public}@", log: customLog, type: .debug, prettyString)
            }
        default:
            break
        }
    }
    
    private func logResponse(_ response: Response) {
        let isError = !(200..<300).contains(response.httpResponse.statusCode)
        let shouldLogThis: Bool = {
            switch loggingConfiguration.responseBehaviour {
            case .all:
                return true
            case .none:
                return false
            case .onlyFailing:
                return isError
            }
        }()
        guard shouldLogThis else { return }
        let customLog = OSLog(subsystem: submoduleName("APIClient"), category: "APIClient.Response")
        let statusCode = NSNumber(value: response.httpResponse.statusCode)
        let path = response.httpResponse.url?.path ?? ""
        os_log("StatusCode: %{public}@ Path: %{public}@", log: customLog, type: .debug, statusCode, path)
        if isError, let errorString = String(data: response.data, encoding: .utf8) {
            os_log("Error Message: %{public}@", log: customLog, type: .error, errorString)
        }
    }
}

extension URLSession: APIClientNetworkFetcher {
    public func fetchData(with urlRequest: URLRequest, urlCache: URLCache?) -> Task<APIClient.Response> {
        let deferred = Deferred<Task<APIClient.Response>.Result>()
        
        guard let cache = urlCache?.cachedResponse(for: urlRequest) else {
            let task = self.dataTask(with: urlRequest) { (data, response, error) in
                self.analyzeResponse(deferred: deferred, data: data, response: response, error: error, urlCache: urlCache, url: urlRequest)
            }
            task.resume()
            return Task(deferred, progress: task.progress)
        }
        self.analyzeResponse(deferred: deferred, data: cache.data, response: cache.response, error: nil, urlCache: urlCache, url: urlRequest)
        return Task(deferred)
    }

    public func uploadFile(with urlRequest: URLRequest, fileURL: URL) -> Task<APIClient.Response> {
        let deferred = Deferred<Task<APIClient.Response>.Result>()
        let urlSessionTask = self.uploadTask(with: urlRequest, fromFile: fileURL) { (data, response, error) in
            self.analyzeResponse(deferred: deferred, data: data, response: response, error: error, url: urlRequest)
        }
        urlSessionTask.resume()
        let task = Task(deferred, progress: urlSessionTask.progress)
        #if os(iOS)
        UIApplication.shared.keepAppAliveUntilTaskCompletes(task)
        #endif
        return task
    }

    private func analyzeResponse(deferred: Deferred<Task<APIClient.Response>.Result>, data: Data?, response: URLResponse?, error: Error?, urlCache: URLCache? = nil, url: URLRequest) {
        guard error == nil else {
            deferred.fill(with: .failure(error!))
            return
        }

        guard let httpResponse = response as? HTTPURLResponse,
            let data = data else {
                deferred.fill(with: .failure(APIClient.Error.malformedResponse))
                return
        }
        
        if let urlCache = urlCache{
            urlCache.storeCachedResponse(CachedURLResponse(response: httpResponse, data: data), for: url)
        }
        deferred.fill(with: .success(APIClient.Response.init(data: data, httpResponse: httpResponse)))
    }
}

private extension Request {
    func performUserValidator(onResponse response: APIClient.Response, queue: DispatchQueue) -> Task<APIClient.Response> {
        return Task.async(upon: queue, onCancel: APIClient.Error.requestCanceled) { () in
            try self.validator(response)
            return response
        }
    }
}

public typealias HTTPHeaders = [String: String]
public struct VoidResponse: Decodable {}

private extension Swift.Error {
    var is401: Bool {
        guard
            let apiClientError = self as? APIClient.Error,
            case .failureStatusCode(let statusCode, _) = apiClientError,
            statusCode == 401 else {
                return false
        }
        return true
    }
}

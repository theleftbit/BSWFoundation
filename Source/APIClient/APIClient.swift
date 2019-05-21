//
//  Created by Pierluigi Cifani on 02/03/2018.
//  Copyright © 2018 TheLeftBit. All rights reserved.
//

import Foundation
import Deferred

public protocol APIClientNetworkFetcher {
    func fetchData(with urlRequest: URLRequest) -> Task<APIClient.Response>
    func uploadFile(with urlRequest: URLRequest, fileURL: URL) -> Task<APIClient.Response>
}

public protocol APIClientDelegate: class {
    func apiClientDidReceiveUnauthorized(forRequest atPath: String, apiClient: APIClient) -> Task<APIClient.Signature>?
}

open class APIClient {

    var delegateQueue = DispatchQueue.main
    public weak var delegate: APIClientDelegate?
    private var router: Router
    private let workerQueue: OperationQueue
    private let workerGCDQueue = DispatchQueue(label: "\(ModuleName).APIClient", qos: .userInitiated)
    private let networkFetcher: APIClientNetworkFetcher

    public static func backgroundClient(environment: Environment, signature: Signature? = nil) -> APIClient {
        let session = URLSession(configuration: .background(withIdentifier: "\(Bundle.main.displayName)-APIClient"))
        return APIClient(environment: environment, signature: signature, networkFetcher: session)
    }

    public init(environment: Environment, signature: Signature? = nil, networkFetcher: APIClientNetworkFetcher? = nil) {
        let queue = queueForSubmodule("APIClient")
        queue.underlyingQueue = workerGCDQueue
        self.router = Router(environment: environment, signature: signature)
        self.networkFetcher = networkFetcher ?? URLSession(configuration: .default, delegate: nil, delegateQueue: queue)
        self.workerQueue = queue
    }

    public func perform<T: Decodable>(_ request: Request<T>) -> Task<T> {
        let task: Task<T> =
            createURLRequest(endpoint: request.endpoint)
                ≈> sendNetworkRequest
                ≈> request.performUserValidator
                ≈> validateResponse
                ≈> parseResponse
        return task.recover(upon: workerGCDQueue) { (error) -> Task<T> in
            return self.attemptToRecoverFrom(error: error, request: request)
        }
    }

    public func performSimpleRequest(forEndpoint endpoint: Endpoint) -> Task<APIClient.Response> {
        return createURLRequest(endpoint: endpoint)
                ≈> sendNetworkRequest
    }
    
    public func addSignature(_ signature: Signature) {
        self.router = Router(
            environment: router.environment,
            signature: signature
        )
    }

    public func removeTokenSignature() {
        self.router = Router(
            environment: router.environment,
            signature: nil
        )
    }
    
    public var currentEnvironment: Environment {
        return self.router.environment
    }
}

extension APIClient {

    public enum Error: Swift.Error {
        case serverError
        case malformedURL
        case malformedParameters
        case malformedResponse
        case encodingRequestFailed
        case multipartEncodingFailed(reason: MultipartFormFailureReason)
        case malformedJSONResponse(Swift.Error)
        case failureStatusCode(Int, Data?)
        case requestCanceled
        case unknownError
        
        public var localizedDescription: String {
            switch self {
            case .serverError:
                return "APIClient.Error.serverError"
            case .malformedURL:
                return "APIClient.Error.malformedURL"
            case .malformedParameters:
                return "APIClient.Error.malformedParameters"
            case .malformedResponse:
                return "APIClient.Error.malformedResponse"
            case .encodingRequestFailed:
                return "APIClient.Error.encodingRequestFailed"
            case .multipartEncodingFailed(let reason):
                return "APIClient.Error.multipartEncodingFailed \(reason)"
            case .malformedJSONResponse(let error):
                return "APIClient.Error.malformedJSONResponse \(error)"
            case .failureStatusCode(let code, _):
                return "APIClient.Error.failureStatusCode \(code)"
            case .requestCanceled:
                return "APIClient.Error.requestCanceled"
            case .unknownError:
                return "APIClient.Error.unknownError"
            }
        }
    }

    public struct Signature {
        let name: String
        let value: String

        public init(name: String, value: String) {
            self.name = name
            self.value = value
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

    func sendNetworkRequest(request: URLRequest, fileURL: URL?) -> Task<APIClient.Response> {
        if let fileURL = fileURL {
            let task = self.networkFetcher.uploadFile(with: request, fileURL: fileURL)
            task.upon(.any()) { (_) in
                self.deleteFileAtPath(fileURL: fileURL)
            }
            return task
        } else {
            return self.networkFetcher.fetchData(with: request)
        }
    }

    func validateResponse(response: Response) -> Task<Data>.Result {
        switch response.httpResponse.statusCode {
        case (200..<300):
            return .success(response.data)
        default:
            let apiError = APIClient.Error.failureStatusCode(response.httpResponse.statusCode, response.data)
            return .failure(apiError)
        }
    }

    func parseResponse<T: Decodable>(data: Data) -> Task<T> {
        return JSONParser.parseData(data)
    }

    func attemptToRecoverFrom<T: Decodable>(error: Swift.Error, request: Request<T>) -> Task<T> {
        guard (error.is401 || error.is403), let newSignatureTask = self.delegate?.apiClientDidReceiveUnauthorized(forRequest: request.endpoint.path, apiClient: self) else {
            return Task(failure: error)
        }
        newSignatureTask.uponSuccess(on: workerGCDQueue) {
            self.addSignature($0)
        }
        return newSignatureTask.andThen(upon: workerGCDQueue) { _ in
            return self.perform(request)
        }
    }

    func createURLRequest(endpoint: Endpoint) -> Task<(URLRequest, URL?)> {
        let deferred = Deferred<Task<(URLRequest, URL?)>.Result>()
        let workItem = DispatchWorkItem {
            do {
                let request = try self.router.urlRequest(forEndpoint: endpoint)
                deferred.fill(with: .success(request))
            } catch let error {
                deferred.fill(with: .failure(error))
            }
        }
        workerGCDQueue.async(execute: workItem)
        return Task(deferred, uponCancel: { [weak workItem] in
            workItem?.cancel()
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
}

extension URLSession: APIClientNetworkFetcher {
    public func fetchData(with urlRequest: URLRequest) -> Task<APIClient.Response> {
        let deferred = Deferred<Task<APIClient.Response>.Result>()
        let task = self.dataTask(with: urlRequest) { (data, response, error) in
            self.analyzeResponse(deferred: deferred, data: data, response: response, error: error)
        }
        task.resume()
        if #available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *) {
            return Task(deferred, progress: task.progress)
        } else {
            return Task(deferred, uponCancel: { [weak task] in
                task?.cancel()
            })
        }
    }

    public func uploadFile(with urlRequest: URLRequest, fileURL: URL) -> Task<APIClient.Response> {
        
        let deferred = Deferred<Task<APIClient.Response>.Result>()
        let task = self.uploadTask(with: urlRequest, fromFile: fileURL) { (data, response, error) in
            self.analyzeResponse(deferred: deferred, data: data, response: response, error: error)
        }
        task.resume()
        if #available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *) {
            return Task(deferred, progress: task.progress)
        } else {
            return Task(deferred, uponCancel: { [weak task] in
                task?.cancel()
            })
        }
    }

    private func analyzeResponse(deferred: Deferred<Task<APIClient.Response>.Result>, data: Data?, response: URLResponse?, error: Error?) {
        guard error == nil else {
            deferred.fill(with: .failure(error!))
            return
        }

        guard let httpResponse = response as? HTTPURLResponse,
            let data = data else {
                deferred.fill(with: .failure(APIClient.Error.malformedResponse))
                return
        }

        deferred.fill(with: .success(APIClient.Response.init(data: data, httpResponse: httpResponse)))
    }
}

private extension Request {
    func performUserValidator(onResponse response: APIClient.Response) -> Task<APIClient.Response> {
        return Task.async(upon: .main, onCancel: APIClient.Error.requestCanceled) { () in
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

    var is403: Bool {
        guard
            let apiClientError = self as? APIClient.Error,
            case .failureStatusCode(let statusCode, _) = apiClientError,
            statusCode == 403 else {
                return false
        }
        return true
    }
}

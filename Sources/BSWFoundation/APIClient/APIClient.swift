//
//  Created by Pierluigi Cifani on 02/03/2018.
//  Copyright © 2018 TheLeftBit. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public protocol APIClientNetworkFetcher {
    func fetchData(with urlRequest: URLRequest) async throws -> APIClient.Response
    func uploadFile(with urlRequest: URLRequest, fileURL: URL) async throws -> APIClient.Response
}

/// This protocol is used to communicate errors during the lifetime of the APIClient
public protocol APIClientDelegate: AnyObject {
    
    /// This method is called when APIClient recieves a 401 and gives a chance to the delegate to update the APIClient's authToken
    /// before retrying the request. Return `true` if you were able to refresh the token. Throw or return false in case you couldn't do it.
    @MainActor func apiClientDidReceiveUnauthorized(forRequest atPath: String, apiClient: APIClient) async throws -> Bool
    
    /// Notifies the delegate of an incoming HTTP error when decoding the response.
    @MainActor func apiClientDidReceiveError(_ error: Error, forRequest atPath: String, apiClient: APIClient) async
}

public extension APIClientDelegate {
    @MainActor func apiClientDidReceiveError(_ error: Error, forRequest atPath: String, apiClient: APIClient) async { }
}

open class APIClient {

    open weak var delegate: APIClientDelegate?
    open var loggingConfiguration = LoggingConfiguration.default
    private let router: Router
    private let networkFetcher: APIClientNetworkFetcher
    private let sessionDelegate: SessionDelegate
    open var mapError: (Swift.Error) -> (Swift.Error) = { $0 }
    open var customizeRequest: (URLRequest) -> (URLRequest) = { $0 }

    public static func backgroundClient(environment: Environment) -> APIClient {
        let session = URLSession(configuration: .background(withIdentifier: "\(Bundle.main.displayName)-APIClient"))
        return APIClient(environment: environment, networkFetcher: session)
    }

    public init(environment: Environment, networkFetcher: APIClientNetworkFetcher? = nil) {
        let sessionDelegate = SessionDelegate(environment: environment)
        self.router = Router(environment: environment)
        self.networkFetcher = networkFetcher ?? URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: .main)
        self.sessionDelegate = sessionDelegate
    }

    public func perform<T: Decodable>(_ request: Request<T>) async throws -> T {
        do {
            let urlRequest = try await router.urlRequest(forEndpoint: request.endpoint)
            let customizedURLRequest = (customizeRequest(urlRequest.0), urlRequest.1)
            let response = try await sendNetworkRequest(customizedURLRequest)
            try request.validator(response)
            let validatedResponse = try await validateResponse(response)
            return try JSONParser.parseData(validatedResponse)
        } catch {
            do {
                return try await attemptToRecoverFrom(error: error, request: request)
            } catch {
                throw self.mapError(error)
            }
        }
    }

    public func performSimpleRequest(forEndpoint endpoint: Endpoint) async throws -> APIClient.Response {
        let request             = try await router.urlRequest(forEndpoint: endpoint)
        let customizedRequest   = (self.customizeRequest(request.0), request.1)
        return try await sendNetworkRequest(customizedRequest)
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

    func sendNetworkRequest(_ networkRequest: NetworkRequest) async throws -> APIClient.Response {
        try Task.checkCancellation()
        logRequest(request: networkRequest.request)
        if let fileURL = networkRequest.fileURL {
            let response = try await self.networkFetcher.uploadFile(with: networkRequest.request, fileURL: fileURL)
            try await self.deleteFileAtPath(fileURL: fileURL)
            return response
        } else {
            return try await self.networkFetcher.fetchData(with: networkRequest.request)
        }
    }

    func validateResponse(_ response: Response) async throws -> Data {
        logResponse(response)
        switch response.httpResponse.statusCode {
        case (200..<300):
            return response.data
        default:
            let apiError = APIClient.Error.failureStatusCode(response.httpResponse.statusCode, response.data)
            
            if let path = response.httpResponse.url?.path {
                await self.delegate?.apiClientDidReceiveError(apiError, forRequest: path, apiClient: self)
            }

            throw apiError
        }
    }

    func attemptToRecoverFrom<T: Decodable>(error: Swift.Error, request: Request<T>) async throws -> T {
        guard error.is401,
            request.shouldRetryIfUnauthorized,
            let delegate = self.delegate else {
            throw error
        }
        let didUpdateSignature = try await delegate.apiClientDidReceiveUnauthorized(forRequest: request.endpoint.path, apiClient: self)
        guard didUpdateSignature else {
            throw error
        }
        let mutatedRequest = Request<T>(
            endpoint: request.endpoint,
            shouldRetryIfUnauthorized: false,
            validator: request.validator
        )
        return try await perform(mutatedRequest)
    }

    func deleteFileAtPath(fileURL: URL) async throws -> Void {
        let void: Void = try await withCheckedThrowingContinuation { continuation in
            FileManagerWrapper.shared.perform { fileManager in
                do {
                    try fileManager.removeItem(at: fileURL)
                    continuation.resume(returning: ())
                } catch let error {
                    continuation.resume(throwing: error)
                }
            }
        }
        return void /// as of Xcode 13.2, this stupid variable was required
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

    @available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
    public func fetchData(with urlRequest: URLRequest) async throws -> APIClient.Response {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            let tuple = try await self.data(for: urlRequest)
            guard let httpResponse = tuple.1 as? HTTPURLResponse else {
                throw APIClient.Error.malformedResponse
            }
            return .init(data: tuple.0, httpResponse: httpResponse)
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                let task = self.dataTask(with: urlRequest) { data, response, error in
                    if let error = error {
                        return continuation.resume(throwing: error)
                    }

                    guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                        return continuation.resume(throwing: APIClient.Error.malformedResponse)
                    }
                    return continuation.resume(returning: .init(data: data, httpResponse: httpResponse))
                }

                task.resume()
            }
        }
    }
    
    @available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
    public func uploadFile(with urlRequest: URLRequest, fileURL: URL) async throws -> APIClient.Response {
        
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
#if os(iOS)
            let backgroundTask = await UIApplication.shared.beginBackgroundTask { }
#endif
            let (data, response) = try await self.upload(for: urlRequest, fromFile: fileURL)
#if os(iOS)
            await UIApplication.shared.endBackgroundTask(backgroundTask)
#endif
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIClient.Error.malformedResponse
            }
            return .init(data: data, httpResponse: httpResponse)
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                let urlSessionTask = self.uploadTask(with: urlRequest, fromFile: fileURL) { (data, response, error) in
                    if let error = error {
                        return continuation.resume(throwing: error)
                    }

                    guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                        return continuation.resume(throwing: APIClient.Error.malformedResponse)
                    }
                    return continuation.resume(returning: .init(data: data, httpResponse: httpResponse))
                }
                urlSessionTask.resume()
            }
        }
    }
}

public typealias HTTPHeaders = [String: String]
public struct VoidResponse: Decodable, Hashable {}

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

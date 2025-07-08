//
//  Created by Pierluigi Cifani on 02/03/2018.
//  Copyright © 2018 TheLeftBit. All rights reserved.
//
import Foundation

#if os(Android)
import FoundationNetworking
#endif

/// Types conforming to this protocol will perform network requests on behalf of `APIClient`
public protocol APIClientNetworkFetcher {
    func fetchData(with urlRequest: URLRequest) async throws -> APIClient.Response
    func uploadFile(with urlRequest: URLRequest, fileURL: URL) async throws -> APIClient.Response
}

/// This protocol is used to communicate errors during the lifetime of the APIClient.
/// You can conform to it on Actors as well as UIKit objects by annotating them as `@MainActor`
public protocol APIClientDelegate: AnyObject {
    
    /// This method is called when APIClient recieves a 401 and gives a chance to the delegate to update the APIClient's authToken
    /// before retrying the request. Return `true` if you were able to refresh the token. Throw or return false in case you couldn't do it.
    func apiClientDidReceiveUnauthorized(forRequest atPath: String, apiClientID: APIClient.ID) async throws -> Bool
    
    /// Notifies the delegate of an incoming HTTP error when decoding the response.
    func apiClientDidReceiveError(_ error: Error, forRequest atPath: String, apiClientID: APIClient.ID) async
}

public extension APIClientDelegate {
    @MainActor func apiClientDidReceiveError(_ error: Error, forRequest atPath: String, apiClientID: APIClient.ID) async { }
}

/// This type allows you to simplify the communications with HTTP servers using the `Environment` protocol and `Request` type.
open class APIClient: Identifiable, @unchecked Sendable {
    
    #if os(Android)
    /// Workaround for https://github.com/skiptools/skip-bridge/issues/49
    public typealias ID = String
    #endif
    
    public var id: String { router.environment.baseURL.absoluteString }
    
    /// Sets the `delegate` for this class
    open weak var delegate: APIClientDelegate?
    
    /// Defines how this object will log to the console the requests and responses.
    open var loggingConfiguration = LoggingConfiguration.default()
    
    /// An optional closure that allows you to map an error before it's thrown
    open var mapError: @Sendable (Swift.Error) -> (Swift.Error) = { $0 }
    
    /// An optional closure that allows you customize a `URLRequest` before it's sent over the network.
    ///
    /// This is useful for example to add an HTTP Header to authenticate with the Server.
    open var customizeRequest: @Sendable (URLRequest) -> (URLRequest) = { $0 }
    
    private let router: Router
    private let networkFetcher: APIClientNetworkFetcher
    private let sessionDelegate: SessionDelegate
    
    /// Initializes the `APIClient`
    /// - Parameters:
    ///   - environment: The `Environment` to attack.
    ///   - networkFetcher: The `APIClientNetworkFetcher` that will perform the network requests. If nil is passed, a `URLSession` with a `.default` configuration will be used.
    public init(environment: Environment, networkFetcher: APIClientNetworkFetcher? = nil) {
        let sessionDelegate = SessionDelegate(environment: environment)
        self.router = Router(environment: environment)
        self.networkFetcher = networkFetcher ?? URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: .main)
        self.sessionDelegate = sessionDelegate
    }
    
    /// Sends a `Request` over the network, validates the response, parses it's contents and returns them.
    /// - Parameter request: The `Request<T>` to perform
    /// - Returns: The parsed response from this request.
    public func perform<T: Decodable>(_ request: Request<T>) async throws -> T {
        do {
            let urlRequest = try await router.urlRequest(forEndpoint: request.endpoint)
            let customizedURLRequest = customizeRequest(urlRequest)
            let response = try await sendNetworkRequest(customizedURLRequest, fileURL: request.endpoint.fileToUpload)
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
    
    /// Sends a `Request` over the network, validates the response and returns the response as-is from the Server..
    /// - Parameter request: The `Request<T>` to perform
    /// - Returns: The `APIClient.Response` from this request.
    public func performSimpleRequest(forEndpoint endpoint: Endpoint) async throws -> APIClient.Response {
        let request             = try await router.urlRequest(forEndpoint: endpoint)
        let customizedRequest   = self.customizeRequest(request)
        return try await sendNetworkRequest(customizedRequest, fileURL: endpoint.fileToUpload)
    }
    
    /// Returns the environment configured for this `APIClient`
    public var currentEnvironment: Environment {
        return router.environment
    }
    
    /// Sets a custom User Agent for the HTTP requests that are sent.
    /// - Note: Specially useful for Android clients since the default User Agent
    /// does not contain the App's name or version.
    public func setCustomUserAgent(_ userAgent: String) async {
        await router.setUserAgentValue(userAgent)
    }
}

extension APIClient {
    
    /// Encapsualtes the Request to be sent to the server.
    public struct Request<ResponseType: Sendable>: Sendable {

        public typealias Validator = @Sendable (APIClient.Response) throws -> ()
        
        /// The Endpoint where to send this request.
        public let endpoint: Endpoint
        
        /// Indicates whether in case of receiving an "Unauthorized response" from the server, if it should be retried after reauthentication succeeds.
        public let shouldRetryIfUnauthorized: Bool
        
        /// An optional closure to make sure any response sent by the server to this request is valid, beyond any default validation that `APIClient` makes
        public let validator: Validator
        
        /// Initializes the Request
        /// - Parameters:
        ///   - endpoint: The Endpoint where to send this request.
        ///   - shouldRetryIfUnauthorized: Indicates whether in case of receiving an "Unauthorized response" from the server, if it should be retried after reauthentication succeeds.
        ///   - validator: An optional closure to make sure any response sent by the server to this request is valid, beyond any default validation that `APIClient` makes.
        public init(endpoint: Endpoint, shouldRetryIfUnauthorized: Bool = true, validator: @escaping Validator = { _ in }) {
            self.endpoint = endpoint
            self.validator = validator
            self.shouldRetryIfUnauthorized = shouldRetryIfUnauthorized
        }
    }

    /// Errors thrown from the `APIClient`.
    public enum Error: Swift.Error, Sendable {
        /// The URL resulting from generating the `URLRequest` is not valid.
        case malformedURL
        /// The response received from the Server is malformed.
        case malformedResponse
        /// Encoding the request failed. This could be because some of the `Endpoint.parameters` are not valid.
        case encodingRequestFailed
        /// The server returned an error Status Code.
        case failureStatusCode(Int, Data?)
    }
    
    /// This type defines how the `APIClient` will log requests and responses into the Console
    public struct LoggingConfiguration: Sendable {
        
        public let requestBehaviour: Behavior
        public let responseBehaviour: Behavior
        
        public init(requestBehaviour: Behavior, responseBehaviour: Behavior) {
            self.requestBehaviour = requestBehaviour
            self.responseBehaviour = responseBehaviour
        }
        
        public static func `default`() -> LoggingConfiguration {
            LoggingConfiguration(requestBehaviour: .none, responseBehaviour: .onlyFailing)
        }
        
        public enum Behavior: Sendable {
            case none
            case all
            case onlyFailing
        }
    }
    
    /// Encapsulates the response received by the server.
    public struct Response: Sendable {
        /// The raw data as received by the server.
        public let data: Data
        /// Other metadata of the response sent by the server encapsulated in a `HTTPURLResponse`
        public let httpResponse: HTTPURLResponse
        
        public init(data: Data, httpResponse: HTTPURLResponse) {
            self.data = data
            self.httpResponse = httpResponse
        }
    }
}

// MARK: Private

private extension APIClient {
    
    func sendNetworkRequest(_ urlRequest: URLRequest, fileURL: URL?) async throws -> APIClient.Response {
        try Task.checkCancellation()
        logRequest(request: urlRequest)
        do {
            if let fileURL {
                return try await networkFetcher.uploadFile(with: urlRequest, fileURL: fileURL)
            } else {
                return try await networkFetcher.fetchData(with: urlRequest)
            }
        } catch {
            logNetworkError(error, forRequest: urlRequest)
            throw error
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
                await self.delegate?.apiClientDidReceiveError(apiError, forRequest: path, apiClientID: id)
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
        let didUpdateSignature = try await delegate.apiClientDidReceiveUnauthorized(forRequest: request.endpoint.path, apiClientID: id)
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

    /// Proxy object to do all our URLSessionDelegate work
    final class SessionDelegate: NSObject, URLSessionDelegate {
        
        let environment: Environment
        
        init(environment: Environment) {
            self.environment = environment
            super.init()
        }
        
        public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
            if environment.shouldAllowInsecureConnections {
                let credential: URLCredential? = {
                    #if os(Android)
                    return (nil)
                    #else
                    return (URLCredential(trust: challenge.protectionSpace.serverTrust!))
                    #endif
                }()
                return (.useCredential, credential)
            } else {
                return (.performDefaultHandling, nil)
            }
        }
    }
}

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

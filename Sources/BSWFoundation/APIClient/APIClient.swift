//
//  Created by Pierluigi Cifani on 02/03/2018.
//  Copyright © 2018 TheLeftBit. All rights reserved.
//
import Foundation
import HTTPTypes

/// A `Decodable` placeholder for endpoints that return no meaningful response body.
public struct VoidResponse: Decodable, Hashable, Sendable {}

/// Types conforming to this protocol will perform network requests on behalf of `APIClient`
public protocol APIClientNetworkFetcher {
    /// Sends the given ``APIClient/OutboundRequest`` over the network and returns the ``APIClient/Response``.
    ///
    /// Implementations should upload ``APIClient/OutboundRequest/fileToUpload`` when it is present,
    /// otherwise send ``APIClient/OutboundRequest/body`` as the request body.
    func perform(_ request: APIClient.OutboundRequest) async throws -> APIClient.Response
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

    /// An optional closure that allows you customize an ``OutboundRequest`` before it's sent over the network.
    ///
    /// This is useful for example to add an HTTP Header to authenticate with the Server.
    open var customizeRequest: @Sendable (OutboundRequest) -> (OutboundRequest) = { $0 }

    private let router: Router
    private let networkFetcher: APIClientNetworkFetcher

    /// Initializes the `APIClient`
    /// - Parameters:
    ///   - environment: The `Environment` to attack.
    ///   - networkFetcher: The `APIClientNetworkFetcher` that will perform the network requests. If nil is passed, a `URLSession`-backed fetcher with a `.default` configuration will be used on platforms where `URLSession` is available.
    public init(environment: Environment, networkFetcher: APIClientNetworkFetcher? = nil) {
        self.router = Router(environment: environment)
        self.networkFetcher = networkFetcher ?? APIClient.makeDefaultNetworkFetcher(environment: environment)
    }

    /// Sends a `Request` over the network, validates the response, parses it's contents and returns them.
    /// - Parameter request: The `Request<T>` to perform
    /// - Returns: The parsed response from this request.
    public func perform<T: Decodable>(_ request: Request<T>) async throws -> T {
        do {
            let outboundRequest = try await router.prepareRequest(forEndpoint: request.endpoint)
            let customizedRequest = customizeRequest(outboundRequest)
            let response = try await sendNetworkRequest(customizedRequest)
            try request.validator(response)
            let validatedResponse = try await validateResponse(response, forPath: request.endpoint.path)
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
        let outboundRequest     = try await router.prepareRequest(forEndpoint: endpoint)
        let customizedRequest   = self.customizeRequest(outboundRequest)
        return try await sendNetworkRequest(customizedRequest)
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
        /// The URL resulting from the `Environment` and `Endpoint` is not valid.
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
        /// The status and header fields of the response, as a portable `HTTPResponse`.
        public let httpResponse: HTTPResponse
        /// The HTTP response status code.
        public var statusCode: Int {
            httpResponse.status.code
        }

        public init(data: Data, httpResponse: HTTPResponse) {
            self.data = data
            self.httpResponse = httpResponse
        }
    }

    /// A transport-agnostic HTTP request, ready to be sent by an ``APIClientNetworkFetcher``.
    ///
    /// The `Router` produces one of these from an `Endpoint`. It bundles the portable `HTTPRequest`
    /// (method, scheme, authority, path and header fields) with the pieces that `HTTPRequest`
    /// deliberately does not carry: the request `body`, an optional `timeoutInterval`, and a
    /// `fileToUpload` when the request is an upload.
    public struct OutboundRequest: Sendable {
        /// The portable HTTP request: method, scheme, authority, path and header fields.
        public var httpRequest: HTTPRequest
        /// The encoded request body, if any.
        public var body: Data?
        /// How long before the request times out, if the `Endpoint` specified it.
        public var timeoutInterval: TimeInterval?
        /// A file to upload, if this is an upload request.
        public var fileToUpload: URL?

        public init(httpRequest: HTTPRequest, body: Data? = nil, timeoutInterval: TimeInterval? = nil, fileToUpload: URL? = nil) {
            self.httpRequest = httpRequest
            self.body = body
            self.timeoutInterval = timeoutInterval
            self.fileToUpload = fileToUpload
        }
    }
}

// MARK: OutboundRequest header conveniences

public extension APIClient.OutboundRequest {

    /// Returns the value of the given HTTP header field, if present.
    ///
    /// Mirrors `URLRequest.value(forHTTPHeaderField:)` so existing `customizeRequest` closures
    /// keep working without reaching for the `HTTPTypes` API directly.
    func value(forHTTPHeaderField field: String) -> String? {
        guard let name = HTTPField.Name(field) else { return nil }
        return httpRequest.headerFields[name]
    }

    /// Sets — replacing any existing values — the value for the given HTTP header field.
    /// Passing `nil` removes the field. No-op if `field` is not a valid header name.
    ///
    /// Mirrors `URLRequest.setValue(_:forHTTPHeaderField:)`.
    mutating func setValue(_ value: String?, forHTTPHeaderField field: String) {
        guard let name = HTTPField.Name(field) else { return }
        httpRequest.headerFields[name] = value
    }

    /// Appends the value for the given HTTP header field, keeping any existing values.
    /// No-op if `field` is not a valid header name.
    ///
    /// Mirrors `URLRequest.addValue(_:forHTTPHeaderField:)`.
    mutating func addValue(_ value: String, forHTTPHeaderField field: String) {
        guard let name = HTTPField.Name(field) else { return }
        httpRequest.headerFields.append(HTTPField(name: name, value: value))
    }
}

// MARK: Private

private extension APIClient {

    func sendNetworkRequest(_ request: OutboundRequest) async throws -> APIClient.Response {
        try Task.checkCancellation()
        logRequest(request)
        do {
            return try await networkFetcher.perform(request)
        } catch {
            logNetworkError(error, forRequest: request)
            throw error
        }
    }

    func validateResponse(_ response: Response, forPath path: String) async throws -> Data {
        logResponse(response, forPath: path)
        switch response.statusCode {
        case (200..<300):
            return response.data
        default:
            let apiError = APIClient.Error.failureStatusCode(response.statusCode, response.data)
            await self.delegate?.apiClientDidReceiveError(apiError, forRequest: path, apiClientID: id)
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

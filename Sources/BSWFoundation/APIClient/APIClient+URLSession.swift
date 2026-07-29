//
//  Created by Pierluigi Cifani on 8/1/25.
//

#if canImport(Darwin) || canImport(FoundationNetworking)

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTPTypes
import HTTPTypesFoundation

//MARK: Default fetcher

extension APIClient {

    /// The `URLSession`-backed fetcher used when no explicit `APIClientNetworkFetcher` is provided.
    static func makeDefaultNetworkFetcher(environment: Environment) -> APIClientNetworkFetcher {
        let sessionDelegate = SessionDelegate(environment: environment)
        return URLSession(configuration: .default, delegate: sessionDelegate, delegateQueue: .main)
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

//MARK: OutboundRequest bridging

extension APIClient.OutboundRequest {
    var urlRequest: URLRequest? {
        guard var urlRequest = URLRequest(httpRequest: self.httpRequest) else { return nil }
        urlRequest.httpBody = self.body
        if let timeoutInterval = self.timeoutInterval {
            urlRequest.timeoutInterval = timeoutInterval
        }
        return urlRequest
    }
}

//MARK: APIClientNetworkFetcher

extension URLSession: APIClientNetworkFetcher {

    public func perform(_ request: APIClient.OutboundRequest) async throws -> APIClient.Response {
        guard var urlRequest = URLRequest(httpRequest: request.httpRequest) else {
            throw APIClient.Error.malformedURL
        }
        if let timeoutInterval = request.timeoutInterval {
            urlRequest.timeoutInterval = timeoutInterval
        }

        if let fileURL = request.fileToUpload {
            return try await performUpload(urlRequest, fromFile: fileURL)
        } else {
            urlRequest.httpBody = request.body
            let (data, response) = try await data(for: urlRequest)
            return try APIClient.Response(data: data, response: response)
        }
    }

    private func performUpload(_ urlRequest: URLRequest, fromFile fileURL: URL) async throws -> APIClient.Response {
        let task = Task {
            try await upload(for: urlRequest, fromFile: fileURL)
        }
        let cancelTask: @Sendable () -> () = {
            task.cancel()
        }
        let wrapper = APIClient.ApplicationWrapper()
        let backgroundTaskID = await wrapper.generateBackgroundTaskID(cancelTask: cancelTask)
        let result: Swift.Result<APIClient.Response, Swift.Error> = await {
            do {
                let (data, response) = try await task.value
                return .success(try APIClient.Response(data: data, response: response))
            } catch {
                return .failure(error)
            }
        }()

        await wrapper.endBackgroundTask(id: backgroundTaskID)
        return try result.get()
    }
}

private extension APIClient.Response {
    /// Bridges a Foundation `URLResponse` into the portable ``APIClient/Response``.
    init(data: Data, response: URLResponse) throws {
        guard let httpURLResponse = response as? HTTPURLResponse,
              let httpResponse = httpURLResponse.httpResponse else {
            throw APIClient.Error.malformedResponse
        }
        self.init(data: data, httpResponse: httpResponse)
    }
}

// MARK: UIApplicationWrapper
/// This is here just to make sure that on non-UIKit
/// platforms we have a nice API to call to.
#if canImport(UIKit.UIApplication)
import UIKit
private extension APIClient {
    class ApplicationWrapper {
        func generateBackgroundTaskID(cancelTask: @escaping (@MainActor @Sendable () -> Void)) async -> UIBackgroundTaskIdentifier {
            return await UIApplication.shared.beginBackgroundTask(expirationHandler: cancelTask)
        }

        func endBackgroundTask(id: UIBackgroundTaskIdentifier) async {
            await UIApplication.shared.endBackgroundTask(id)
        }
    }
}
#else
private extension APIClient {
    class ApplicationWrapper {
        func generateBackgroundTaskID(cancelTask: @escaping (@MainActor @Sendable () -> Void)) async -> Int {
            return 0
        }

        func endBackgroundTask(id: Int) async {

        }
    }
}
#endif


#endif

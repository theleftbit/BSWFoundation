//
//  Created by Pierluigi Cifani on 8/1/25.
//

import Foundation

#if os(Android)
import FoundationNetworking
#endif

//MARK: APIClientNetworkFetcher

extension URLSession: APIClientNetworkFetcher {

    public func fetchData(with urlRequest: URLRequest) async throws -> APIClient.Response {
        let tuple = try await data(for: urlRequest)
        guard let httpResponse = tuple.1 as? HTTPURLResponse else {
            throw APIClient.Error.malformedResponse
        }
        return .init(data: tuple.0, httpResponse: httpResponse)
    }
    
    public func uploadFile(with urlRequest: URLRequest, fileURL: URL) async throws -> APIClient.Response {
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
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIClient.Error.malformedResponse
                }
                return .success(APIClient.Response(data: data, httpResponse: httpResponse))
            } catch {
                return .failure(error)
            }
        }()

        await wrapper.endBackgroundTask(id: backgroundTaskID)
        return try result.get()
    }
}

public typealias HTTPHeaders = [String: String]
public struct VoidResponse: Decodable, Hashable, Sendable {}

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


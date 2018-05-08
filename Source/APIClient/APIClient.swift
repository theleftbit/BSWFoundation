//
//  Created by Pierluigi Cifani on 02/03/2018.
//  Copyright © 2018 TheLeftBit. All rights reserved.
//

import Foundation
import Deferred

public protocol APIClientNetworkFetcher {
    func fetchData(with urlRequest: URLRequest) -> Task<Data>
}

open class APIClient {

    var delegateQueue = DispatchQueue.main
    private let router: Router
    private let jsonDecoder = JSONDecoder()
    private let workerQueue: OperationQueue
    private let networkFetcher: APIClientNetworkFetcher

    public init(environment: Environment, signature: Signature? = nil, networkFetcher: APIClientNetworkFetcher? = nil) {
        let queue = queueForSubmodule("APIClient", qualityOfService: .userInitiated)
        self.router = Router(environment: environment, signature: signature)
        self.networkFetcher = networkFetcher ?? URLSession(configuration: .default, delegate: nil, delegateQueue: queue)
        self.workerQueue = queue
    }

    public func perform<T: Decodable>(_ request: Request<T>) -> Task<T> {
        return createURLRequest(endpoint: request.endpoint)
                ≈> networkFetcher.fetchData
                ≈> parseResponse
    }
}

extension APIClient {

    public enum Error: Swift.Error {
        case serverError
        case malformedURL
        case malformedParameters
        case malformedResponse
        case encodingRequestFailed
        case malformedJSONResponse(Swift.Error)
        case failureStatusCode(Int)
        case unknownError
    }

    public struct Signature {
        let name: String
        let value: String
    }
}

// MARK: Private

private extension APIClient {

    func parseResponse<T: Decodable>(data: Data) -> Task<T> {
        let deferred = Deferred<Task<T>.Result>()
        let blockOperation = BlockOperation {
            do {
                let response: T = try self.jsonDecoder.decode(T.self, from: data)
                deferred.fill(with: .success(response))
            } catch let error {
                deferred.fill(with: .failure(Error.malformedJSONResponse(error)))
            }
        }
        workerQueue.addOperation(blockOperation)
        return Task(deferred, cancellation: { [weak blockOperation] in
            blockOperation?.cancel()
        })
    }

    func createURLRequest(endpoint: Endpoint) -> Task<URLRequest> {
        let deferred = Deferred<Task<URLRequest>.Result>()
        let blockOperation = BlockOperation {
            do {
                let request: URLRequest = try self.router.urlRequest(forEndpoint: endpoint)
                deferred.fill(with: .success(request))
            } catch let error {
                deferred.fill(with: .failure(error))
            }
        }
        workerQueue.addOperation(blockOperation)
        return Task(deferred, cancellation: { [weak blockOperation] in
            blockOperation?.cancel()
        })
    }
}

extension URLSession: APIClientNetworkFetcher {
    public func fetchData(with urlRequest: URLRequest) -> Task<Data> {
        let deferred = Deferred<Task<Data>.Result>()
        let task = self.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil else {
                deferred.fill(with: .failure(error!))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                let data = data else {
                    deferred.fill(with: .failure(APIClient.Error.malformedResponse))
                    return
            }

            deferred.fill(with: .success(data))
        }
        task.resume()
        return Task(deferred, cancellation: { [weak task] in
            task?.cancel()
        })
    }
}

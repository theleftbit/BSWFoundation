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

    let environment: Environment
    let signature: Signature?
    let jsonDecoder = JSONDecoder()
    var delegateQueue = DispatchQueue.main
    let workerQueue: OperationQueue
    let networkFetcher: APIClientNetworkFetcher

    public init(environment: Environment, signature: Signature? = nil, networkFetcher: APIClientNetworkFetcher? = nil) {
        let queue = queueForSubmodule("APIClient", qualityOfService: .userInitiated)
        self.environment = environment
        self.signature = signature
        self.networkFetcher = networkFetcher ?? URLSession(configuration: .default, delegate: nil, delegateQueue: queue)
        self.workerQueue = queue
    }

    public func perform<T: Decodable>(_ request: Request<T>) -> Task<T> {

        let urlRequest: Task<URLRequest> = self.createURLRequest(endpoint: request.endpoint)
        let downloadData: Task<Data> = urlRequest.andThen(upon: workerQueue) {
            return self.networkFetcher.fetchData(with: $0)
        }
        let parseData: Task<T> = downloadData.andThen(upon: workerQueue) {
            return self.parseResponse(data: $0)
        }
        return parseData
    }
}

extension APIClient {

    public enum Error: Swift.Error {
        case serverError
        case malformedURL
        case malformedParameters
        case malformedResponse
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
                let request: URLRequest = try self.createURLRequest(endpoint: endpoint)
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

    func createURLRequest(endpoint: Endpoint) throws -> URLRequest {
        guard let URL = URL(string: endpoint.path, relativeTo: self.environment.baseURL) else {
            throw Error.malformedURL
        }

        var urlRequest = URLRequest(url: URL)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.allHTTPHeaderFields = endpoint.httpHeaderFields
        urlRequest.setValue(Bundle.main.displayName, forHTTPHeaderField: "User-Agent")
        if let signature = self.signature {
            urlRequest.setValue(
                signature.value,
                forHTTPHeaderField: signature.name
            )
        }
        if let parameters = endpoint.parameters {
            do {
                let requestData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                urlRequest.httpBody = requestData
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw Error.malformedParameters
            }
        }
        return urlRequest
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

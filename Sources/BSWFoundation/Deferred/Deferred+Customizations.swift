//
//  Result+Deferred.swift
//  Created by Pierluigi Cifani on 20/04/16.
//

import Task; import Deferred
import Foundation

//MARK: Legacy APIs using Deferred

extension APIClient {
    public func perform<T: Decodable>(_ request: Request<T>) -> Task<T> {
        Task.fromSwiftConcurrency { try await self.perform(request) }
    }

    public func performSimpleRequest(forEndpoint endpoint: Endpoint) -> Task<APIClient.Response> {
        Task.fromSwiftConcurrency { try await self.performSimpleRequest(forEndpoint: endpoint )}
    }
}

import CoreLocation

public extension LocationFetcher {
    func fetchCurrentLocation(_ useCachedLocationIfAvailable: Bool = true) -> Task<CLLocation> {
        Task.fromSwiftConcurrency { try await self.fetchCurrentLocation(useCachedLocationIfAvailable) }
    }
}

extension JSONParser {
    public static func parseData<T: Decodable>(_ data: Data) -> Task<T> {
        Task.fromSwiftConcurrency { try self.parseData(data) }
    }
}

//MARK: Public

public func both<T, U>(first: Task<T>, second: Task<U>) ->  Task<(T, U)> {
    
    let deferred = Deferred<Task<(T, U)>.Result>()
    first.and(second).upon { (tuple) in
        guard let firstValue = tuple.0.value else {
            deferred.fill(with: .failure(tuple.0.error!))
            return
        }
        
        guard let secondValue = tuple.1.value else {
            deferred.fill(with: .failure(tuple.1.error!))
            return
        }
        
        deferred.fill(with: .success((firstValue, secondValue)))
    }
    
    return Task(Future(deferred))
}

public func bothSerially<T, U>(first: Task<T>, second: @escaping (T) -> Task<U>) ->  Task<(T, U)> {
    
    let deferred = Deferred<Task<(T, U)>.Result>()
    
    first.upon { (firstResult) in
        guard let firstValue = firstResult.value else {
            deferred.fill(with: .failure(firstResult.error!))
            return
        }
        
        second(firstValue).upon { (secondResult) in
            guard let secondValue = secondResult.value else {
                deferred.fill(with: .failure(secondResult.error!))
                return
            }
            
            deferred.fill(with: .success((firstValue, secondValue)))
        }
    }
    return Task(Future(deferred))
}

extension Task {
    
    public func toSwiftConcurrency() async throws -> Success {
        try await withCheckedThrowingContinuation { cont in
            toObjectiveC { success, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: success!)
                }
            }
        }
    }

    public func toObjectiveC(completionHandler handler: @escaping (Success?, NSError?) -> Void) {
        upon(.main) { (result) in
            switch result {
            case .success(let value):
                handler(value, nil)
            case .failure(let error):
                handler(nil, error as NSError)
            }
        }
    }
    
    public typealias SwiftConcurrencySignature = () async throws -> Success
    
    public static func fromSwiftConcurrency(_ closure: @escaping SwiftConcurrencySignature) -> Task<Success> {
        let deferred = Deferred<Task<Success>.Result>()
        let swiftTask = _Concurrency.Task {
            do {
                let object: Success = try await closure()
                deferred.fill(with: .success(object))
            } catch {
                deferred.fill(with: .failure(error))
            }
        }
        return Task(deferred, uponCancel: {
            swiftTask.cancel()
        })
    }
}

extension Future {
    public typealias SwiftConcurrencySignature = () async -> Value?
    public static func fromSwiftConcurrency(_ closure: @escaping SwiftConcurrencySignature) -> Future<Value?> {
        let deferred = Deferred<Value?>()
        _Concurrency.Task {
            let object: Value? = await closure()
            deferred.fill(with: object)
        }
        return Future<Value?>(deferred)
    }
}

extension Task.Result {
    public var value: Success? {
        switch self {
        case .success(let value):
            return value
        case .failure(_):
            return nil
        }
    }

    public var error: Error? {
        switch self {
        case .success(_):
            return nil
        case .failure(let error):
            return error
        }
    }
    
    /// Returns a new Result by mapping `Success`es’ values using `transform`, or re-wrapping `Failure`s’ errors.
    public func map<OtherValue>(_ transform: (Success) -> OtherValue) -> Task<OtherValue>.Result {
        return flatMap { .success(transform($0)) }
    }
    
    /// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
    public func flatMap<OtherValue>(_ transform: (Success) -> Task<OtherValue>.Result) -> Task<OtherValue>.Result {
        switch self {
        case .failure(let error):
            return .failure(error)
        case .success(let value):
            return transform(value)
        }
    }    
}
 
public extension Task.Result {
    func extract() throws -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    var swiftResult: Swift.Result<Success, Error> {
        switch self {
        case .failure(let error):
            return .failure(error)
        case .success(let value):
            return .success(value)
        }
    }
}

#if os(iOS)

import UIKit

public extension UIApplication {
    func keepAppAliveUntilTaskCompletes<T>(_ task: Task<T>) {
        let backgroundTask = self.beginBackgroundTask {
            task.cancel()
        }
        task.upon(.main) { (_) in
            self.endBackgroundTask(backgroundTask)
        }
    }
}

#endif

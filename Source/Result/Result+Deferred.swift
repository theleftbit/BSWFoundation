//
//  Result+Deferred.swift
//  Created by Pierluigi Cifani on 20/04/16.
//

import Deferred

//MARK: Public

infix operator ≈> { associativity left precedence 160 }

public func ≈> <T, U>(lhs: Future<Result<T>>, rhs: @escaping (T) -> Future<Result<U>>) -> Future<Result<U>> {
    return lhs.andThen(upon: DispatchQueue.any()) { resultToDeferred($0, f: rhs) }
}

public func ≈> <T, U>(lhs: Future<Result<T>>, rhs: @escaping (T) -> Result<U>) -> Future<Result<U>> {
    return lhs.andThen(upon: DispatchQueue.any()) { resultToDeferred($0, f: rhs) }
}

public func ≈> <T, U>(lhs: Future<Result<T>>, rhs: @escaping (T) -> U) -> Future<Result<U>> {
    return lhs.andThen(upon: DispatchQueue.any()) { resultToDeferred($0, f: rhs) }
}

public func ≈> <T, U>(lhs: Future<T>, rhs: @escaping (T) -> Result<U>) -> Future<Result<U>> {
    return lhs.map(upon: DispatchQueue.any()) { return rhs($0) }
}

public func both <T, U> (first: Future<Result<T>>, second: Future<Result<U>>) ->  Future<Result<(T, U)>> {
    
    let deferred = Deferred<Result<(T, U)>>()
    
    first.and(second).upon { (firstResult, secondResult) in
        guard let firstValue = firstResult.value else {
            deferred.fill(with: Result(error: firstResult.error!))
            return
        }
        
        guard let secondValue = secondResult.value else {
            deferred.fill(with: Result(error: secondResult.error!))
            return
        }
        
        deferred.fill(with: Result((firstValue, secondValue)))
    }
    
    return Future(deferred)
}

public func bothSerially <T, U> (first: Future<Result<T>>, second: @escaping (T) -> Future<Result<U>>) ->  Future<Result<(T, U)>> {
    
    let deferred = Deferred<Result<(T, U)>>()
    
    first.upon{ (firstResult) in
        guard let firstValue = firstResult.value else {
            deferred.fill(with: .failure(firstResult.error!))
            return
        }
        
        second(firstValue).upon { (secondResult) in        
            guard let secondValue = secondResult.value else {
                deferred.fill(with: .failure(secondResult.error!))
                return
            }
            
            deferred.fill(with: Result((firstValue, secondValue)))
        }
    }
    
    return Future(deferred)
}

extension Future where Value: ResultType {
    func toObjectiveC<T>(completionHandler handler: (T?, NSError?) -> Void) {
        uponMainQueue { (result) in
            if let error = result.error {
                handler(nil, error as NSError)
            } else if let value = result.value as? T {
                handler(value, nil)
            } else {
                handler(nil, NSError(domain: "BSWFoundation", code: -10, userInfo: nil))
            }
        }
    }
}

//MARK: Private

private func resultToDeferred <T, U>(_ result: Result<T>, f: (T) -> Future<Result<U>>) -> Future<Result<U>> {
    switch result {
    case let .success(value):
        return f(value)
    case let .failure(error):
        return Future(value: .failure(error))
    }
}

private func resultToDeferred <T, U>(_ result: Result<T>, f: (T) -> Result<U>) -> Future<Result<U>> {
    switch result {
    case let .success(value):
        return Future(value: f(value))
    case let .failure(error):
        return Future(value: .failure(error))
    }
}

private func resultToDeferred <T, U>(_ result: Result<T>, f: (T) -> U) -> Future<Result<U>> {
    switch result {
    case let .success(value):
        return Future(value: .success(f(value)))
    case let .failure(error):
        return Future(value: .failure(error))
    }
}

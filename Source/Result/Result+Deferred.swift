//
//  Result+Deferred.swift
//  Created by Pierluigi Cifani on 20/04/16.
//

import Deferred

//MARK: Public

infix operator ≈> { associativity left precedence 160 }

public func ≈> <T, U>(lhs: Future<Result<T>>, rhs: T -> Future<Result<U>>) -> Future<Result<U>> {
    return lhs.flatMap { resultToDeferred($0, f: rhs) }
}

public func ≈> <T, U>(lhs: Future<Result<T>>, rhs: T -> Result<U>) -> Future<Result<U>> {
    return lhs.flatMap { resultToDeferred($0, f: rhs) }
}

public func ≈> <T, U>(lhs: Future<Result<T>>, rhs: T -> U) -> Future<Result<U>> {
    return lhs.flatMap { resultToDeferred($0, f: rhs) }
}

public func ≈> <T, U>(lhs: Future<T>, rhs: T -> Result<U>) -> Future<Result<U>> {
    return lhs.map { return rhs($0) }
}

public func both <T, U> (first first: Future<Result<T>>, second: Future<Result<U>>) ->  Future<Result<(T, U)>> {
    
    let deferred = Deferred<Result<(T, U)>>()
    
    first.and(second).upon { (firstResult, secondResult) in
        guard let firstValue = firstResult.value else {
            deferred.fill(Result(error: firstResult.error!))
            return
        }
        
        guard let secondValue = secondResult.value else {
            deferred.fill(Result(error: secondResult.error!))
            return
        }
        
        deferred.fill(Result((firstValue, secondValue)))
    }
    
    return Future(deferred)
}

public func bothSerially <T, U> (first first: Future<Result<T>>, second: T -> Future<Result<U>>) ->  Future<Result<(T, U)>> {
    
    let deferred = Deferred<Result<(T, U)>>()
    
    first.upon{ (firstResult) in
        guard let firstValue = firstResult.value else {
            deferred.fill(Result(error: firstResult.error!))
            return
        }
        
        second(firstValue).upon { (secondResult) in        
            guard let secondValue = secondResult.value else {
                deferred.fill(Result(error: secondResult.error!))
                return
            }
            
            deferred.fill(Result((firstValue, secondValue)))
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

private func resultToDeferred <T, U>(result: Result<T>, f: T -> Future<Result<U>>) -> Future<Result<U>> {
    switch result {
    case let .Success(value):
        return f(value)
    case let .Failure(error):
        return Future(value: Result.Failure(error))
    }
}

private func resultToDeferred <T, U>(result: Result<T>, f: T -> Result<U>) -> Future<Result<U>> {
    switch result {
    case let .Success(value):
        return Future(value: f(value))
    case let .Failure(error):
        return Future(value: Result.Failure(error))
    }
}

private func resultToDeferred <T, U>(result: Result<T>, f: T -> U) -> Future<Result<U>> {
    switch result {
    case let .Success(value):
        return Future(value: Result.Success(f(value)))
    case let .Failure(error):
        return Future(value: Result.Failure(error))
    }
}

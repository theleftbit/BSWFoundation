//
//  Result+Deferred.swift
//  Created by Pierluigi Cifani on 20/04/16.
//

import Deferred

//MARK: Public

precedencegroup Additive {
    associativity: left
}

infix operator ≈> : Additive

public func ≈> <T, U>(lhs: Task<T>, rhs: @escaping (T) -> Task<U>) -> Task<U> {
    return lhs.andThen(upon: DispatchQueue.any(), start: rhs)
}

public func ≈> <T, U>(lhs: Task<T>, rhs: @escaping (T) -> TaskResult<U>) -> Task<U> {
    return lhs.andThen(upon: DispatchQueue.any()) { Task(Future(value: rhs($0))) }
}

public func ≈> <T, U>(lhs: Task<T>, rhs: @escaping (T) -> U) -> Task<U> {
    return lhs.andThen(upon: DispatchQueue.any()) { return Task(future: Future(value: .success(rhs($0)))) }
}

public func ≈> <T, U>(lhs: Future<T>, rhs: @escaping (T) -> TaskResult<U>) -> Task<U> {
    return Task(future: lhs.map(upon: DispatchQueue.any()) { return rhs($0) })
}

public func both <T, U> (first: Task<T>, second: Task<U>) ->  Task<(T, U)> {
    
    let deferred = Deferred<TaskResult<(T, U)>>()
    
    first.and(second).upon { (firstResult, secondResult) in
        guard let firstValue = firstResult.value else {
            deferred.fill(with: .failure(firstResult.error!))
            return
        }
        
        guard let secondValue = secondResult.value else {
            deferred.fill(with: .failure(secondResult.error!))
            return
        }
        
        deferred.fill(with: .success((firstValue, secondValue)))
    }
    
    return Task(future: Future(deferred))
}

public func bothSerially <T, U> (first: Task<T>, second: @escaping (T) -> Task<U>) ->  Task<(T, U)> {
    
    let deferred = Deferred<TaskResult<(T, U)>>()
    
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
            
            deferred.fill(with: .success((firstValue, secondValue)))
        }
    }
    
    return Task(future: Future(deferred))
}

extension Task {
    func toObjectiveC(completionHandler handler: @escaping (SuccessValue?, NSError?) -> Void) {
        upon(.main) { (result) in
            switch result {
            case .success(let value):
                handler(value, nil)
            case .failure(let error):
                handler(nil, error as NSError)
            }
        }
    }
}

extension TaskResult {
    var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure(_):
            return nil
        }
    }

    var error: Error? {
        switch self {
        case .success(_):
            return nil
        case .failure(let error):
            return error
        }
    }
    
    /// Returns a new Result by mapping `Success`es’ values using `transform`, or re-wrapping `Failure`s’ errors.
    public func map<OtherValue>(_ transform: (Value) -> OtherValue) -> TaskResult<OtherValue> {
        return flatMap { .success(transform($0)) }
    }
    
    /// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
    public func flatMap<OtherValue>(_ transform: (Value) -> TaskResult<OtherValue>) -> TaskResult<OtherValue> {
        switch self {
        case .failure(let error):
            return .failure(error)
        case .success(let value):
            return transform(value)
        }
    }    
}

//MARK: Deprecated

@available(*, deprecated, message: "use Task<T> instead")
public func ≈> <T, U>(lhs: Future<Result<T>>, rhs: @escaping (T) -> Future<Result<U>>) -> Future<Result<U>> {
    return lhs.andThen(upon: DispatchQueue.any()) { resultToDeferred($0, f: rhs) }
}

@available(*, deprecated, message: "use Task<T> instead")
public func ≈> <T, U>(lhs: Future<Result<T>>, rhs: @escaping (T) -> Result<U>) -> Future<Result<U>> {
    return lhs.andThen(upon: DispatchQueue.any()) { resultToDeferred($0, f: rhs) }
}

@available(*, deprecated, message: "use Task<T> instead")
public func ≈> <T, U>(lhs: Future<Result<T>>, rhs: @escaping (T) -> U) -> Future<Result<U>> {
    return lhs.andThen(upon: DispatchQueue.any()) { resultToDeferred($0, f: rhs) }
}

@available(*, deprecated, message: "use Task<T> instead")
public func ≈> <T, U>(lhs: Future<T>, rhs: @escaping (T) -> Result<U>) -> Future<Result<U>> {
    return lhs.map(upon: DispatchQueue.any()) { return rhs($0) }
}

@available(*, deprecated, message: "use Task<T> instead")
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

@available(*, deprecated, message: "use Task<T> instead")
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

@available(*, deprecated, message: "use Task<T> instead")
extension Future where Value: ResultProtocol {
    func toObjectiveC<T>(completionHandler handler: @escaping (T?, NSError?) -> Void) {
        upon(.main) { (result) in
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

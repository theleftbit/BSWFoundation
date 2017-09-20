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

public func ≈> <T, U>(lhs: Task<T>, rhs: @escaping (T) -> Task<U>.Result) -> Task<U> {
    return lhs.andThen(upon: DispatchQueue.any()) { Task(Future(value: rhs($0))) }
}

public func ≈> <T, U>(lhs: Task<T>, rhs: @escaping (T) -> U) -> Task<U> {
    return lhs.andThen(upon: DispatchQueue.any()) { return Task(future: Future(value: .success(rhs($0)))) }
}

public func ≈> <T, U>(lhs: Future<T>, rhs: @escaping (T) -> Task<U>.Result) -> Task<U> {
    return Task(future: lhs.map(upon: DispatchQueue.any()) { return rhs($0) })
}

public func ≈> <T, U>(lhs: Task<T>, rhs: @escaping (T) throws -> U) -> Task<U> {
    return lhs.andThen(upon: DispatchQueue.any()) {(input) throws -> Task<U> in
        let value = try rhs(input)
        return Task(future: Future(value: .success(value)))
    }
}

infix operator ==> : Additive

public func ==> <T, U>(lhs: Task<T>, rhs: @escaping (T) -> Task<U>) -> Task<U> {
    return lhs.andThen(upon: DispatchQueue.main, start: rhs)
}

public func ==> <T, U>(lhs: Task<T>, rhs: @escaping (T) -> Task<U>.Result) -> Task<U> {
    return lhs.andThen(upon: DispatchQueue.main) { Task(Future(value: rhs($0))) }
}

public func ==> <T, U>(lhs: Task<T>, rhs: @escaping (T) -> U) -> Task<U> {
    return lhs.andThen(upon: DispatchQueue.main) { return Task(future: Future(value: .success(rhs($0)))) }
}

public func ==> <T, U>(lhs: Future<T>, rhs: @escaping (T) -> Task<U>.Result) -> Task<U> {
    return Task(future: lhs.map(upon: DispatchQueue.main) { return rhs($0) })
}

public func ==> <T, U>(lhs: Task<T>, rhs: @escaping (T) throws -> U) -> Task<U> {
    return lhs.andThen(upon: DispatchQueue.main) {(input) throws -> Task<U> in
        let value = try rhs(input)
        return Task(future: Future(value: .success(value)))
    }
}

public func both <T, U> (first: Task<T>, second: Task<U>) ->  Task<(T, U)> {
    
    let deferred = Deferred<Task<(T, U)>.Result>()
    first.and(second).upon { (tuple) in
        guard let firstValue = tuple.0.value else {
            deferred.fill(with: .failure(tuple.0.error!))
            return
        }
        
        guard let secondValue = tuple.1.value else {
            deferred.fill(with: .failure(tuple.0.error!))
            return
        }
        
        deferred.fill(with: .success((firstValue, secondValue)))
    }
    
    return Task(future: Future(deferred))
}

public func bothSerially <T, U> (first: Task<T>, second: @escaping (T) -> Task<U>) ->  Task<(T, U)> {
    
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
    
    return Task(future: Future(deferred))
}

extension Task {
    public func toObjectiveC(completionHandler handler: @escaping (SuccessValue?, NSError?) -> Void) {
        upon(.main) { (result) in
            switch result {
            case .success(let value):
                handler(value, nil)
            case .failure(let error):
                handler(nil, error as NSError)
            }
        }
    }
    
    public func recover(upon executor: Executor, start startNextTask: @escaping(Error) -> Task<SuccessValue>) -> Task<SuccessValue> {
        
        let future: Future<Task<SuccessValue>.Result> = andThen(upon: executor) { (result) -> Task<SuccessValue> in
            do {
                let value = try result.extract()
                return Task<SuccessValue>(success: value)
            } catch let error {
                return startNextTask(error)
            }
        }
        
        return Task<SuccessValue>(future: future)
    }
}

extension Task.Result {
    public var value: SuccessValue? {
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
    public func map<OtherValue>(_ transform: (SuccessValue) -> OtherValue) -> Task<OtherValue>.Result {
        return flatMap { .success(transform($0)) }
    }
    
    /// Returns the result of applying `transform` to `Success`es’ values, or re-wrapping `Failure`’s errors.
    public func flatMap<OtherValue>(_ transform: (SuccessValue) -> Task<OtherValue>.Result) -> Task<OtherValue>.Result {
        switch self {
        case .failure(let error):
            return .failure(error)
        case .success(let value):
            return transform(value)
        }
    }    
}

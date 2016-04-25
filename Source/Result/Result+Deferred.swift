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

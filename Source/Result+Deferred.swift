//
//  Result+Deferred.swift
//  Created by Pierluigi Cifani on 20/04/16.
//

import Result
import Deferred

//MARK: Public

infix operator ≈> { associativity left precedence 160 }

public func ≈> <T, U>(lhs: Future<Result<T, FoundationErrorKind>>, rhs: T -> Future<Result<U, FoundationErrorKind>>) -> Future<Result<U, FoundationErrorKind>> {
    let deferred = lhs.flatMap { resultToDeferred($0, f: rhs) }
    return deferred
}

public func ≈> <T, U>(lhs: Deferred<T>, rhs: T -> Deferred<Result<U, FoundationErrorKind>>) -> Future<Result<U, FoundationErrorKind>> {
    let deferred = lhs.flatMap { rhs($0) }
    return deferred
}

/**
 Generic error container a-la `NSError`
 - Note: This is due to the fact that `Result<T, ErrorKind>` requires a concrete
 error type to be initialized, and it's impossible to write the `≈>` and still carry
 the error type information, since there is no way of express what kind of errors can
 be thrown from a sequence of chained asynchronous operation that might fail
 */
public struct FoundationErrorKind: ResultErrorType {
    let wrappedError: ResultErrorType
}

//MARK: Private

private func resultToDeferred <T, U>(result: Result<T, FoundationErrorKind>, f: T -> Future<Result<U, FoundationErrorKind>>) -> Future<Result<U, FoundationErrorKind>> {
    switch result {
    case let .Success(value):
        return f(value)
    case let .Failure(error):
        return Future(value: Result.Failure(error))
    }
}


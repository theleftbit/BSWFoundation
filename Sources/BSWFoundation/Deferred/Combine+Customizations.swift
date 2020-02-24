//
//  Created by Pierluigi Cifani on 27/07/2019.
//

#if canImport(Combine)
import Combine
import Task
import Foundation

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias CombineTask<T> = Combine.Future<T, Swift.Error>

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Task {
    var future: CombineTask<Success> {
        return .init { (promise) in
            self.upon(DispatchQueue.any()) { (result) in
                switch result {
                case .success(let value):
                    promise(.success(value))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }
    var publisher: AnyPublisher<Success, Error> {
        return future.eraseToAnyPublisher()
    }
}

#if canImport(XCTest)

import XCTest

public extension XCTestCase {
    
    @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func waitAndExtractValue<T>(_ publisher: CombineTask<T>, timeout: TimeInterval = 1) throws -> T {
        var catchedValue: T!
        var catchedError: Swift.Error!
        let exp = self.expectation(description: "Extract from publisher")
        _ = publisher.sink(receiveCompletion: { (completion) in
            switch completion {
            case .failure(let error):
                catchedError = error
            case .finished:
                break
            }
            exp.fulfill()
        }) { (value) in
            catchedValue = value
        }
        self.waitForExpectations(timeout: timeout) { (timeoutError) in
            if let timeoutError = timeoutError {
                catchedError = timeoutError
            }
        }
        
        if let error = catchedError {
            throw error
        }
        return catchedValue
    }
}

#endif
#endif


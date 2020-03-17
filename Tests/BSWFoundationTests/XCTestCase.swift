
#if canImport(XCTest)
#if canImport(Combine)

import XCTest
import Combine
import BSWFoundation

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

#if canImport(XCTest)

import Task
import XCTest

public extension XCTestCase {
    func waitAndExtractValue<T>(_ task: Task<T>, timeout: TimeInterval = 1) throws -> T {
        var catchedValue: T!
        var catchedError: Swift.Error!
        let exp = self.expectation(description: "Extract from Future")
        task.upon(.main) { (result) in
            switch result {
            case .failure(let error):
                catchedError = error
            case .success(let value):
                catchedValue = value
            }
            exp.fulfill()
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

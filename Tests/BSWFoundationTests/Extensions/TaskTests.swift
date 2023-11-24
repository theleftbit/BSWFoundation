#if os(Android)
#else

import XCTest
import BSWFoundation

class TaskTests: XCTestCase {
    func testNever() throws {
        let waiter = XCTWaiter()
        let exp = self.expectation(description: " ")
        let task = Task(priority: .userInitiated) {
            let _ = try await Task.never
            exp.fulfill()
        }
        waiter.wait(for: [exp], timeout: 1)
        XCTAssert(waiter.fulfilledExpectations.isEmpty)
        task.cancel()
    }
    
    func testNeverFuncOverride() throws {
        @Sendable func someThingThatReturnsAValue() async throws -> Int {
            try await Task.never()
        }
        let waiter = XCTWaiter()
        let exp = self.expectation(description: " ")
        let task = Task(priority: .userInitiated) {
            let _ = try await someThingThatReturnsAValue()
            exp.fulfill()
        }
        waiter.wait(for: [exp], timeout: 1)
        XCTAssert(waiter.fulfilledExpectations.isEmpty)
        task.cancel()
    }
}
#endif

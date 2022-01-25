
import XCTest
import BSWFoundation

class TaskTests: XCTestCase {
    func testNever() async throws {
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
}

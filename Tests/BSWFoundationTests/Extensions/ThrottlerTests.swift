import Foundation
import XCTest
import BSWFoundation

class ThrottlerTests: XCTestCase {
    func testItWorks() {
        let sut = Throttler(seconds: 0.5)
        var numberOfTimesThisIsExecuted = 0
        let exp = expectation(description: "must be filled once")
        let work = {
            numberOfTimesThisIsExecuted += 1
            exp.fulfill()
        }
        sut.throttle(block: work)
        sut.throttle(block: work)
        sut.throttle(block: work)
        sut.throttle(block: work)
        sut.throttle(block: work)
        wait(for: [exp], timeout: 1)
        XCTAssert(numberOfTimesThisIsExecuted == 1)
    }
}

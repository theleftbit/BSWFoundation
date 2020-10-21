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

    /// The job of this test is to make sure that work sent to the Throttler is not executed immediatelly,
    /// but rather at least `maxInterval` is waited. In this test case, we want to check that nothing
    /// is executed because we're checking 10 milliseconds before `maxInterval` expires.
    func testItDoesntJustSpitTheFirstJobButRatherWaitsForTheDelayToKickIn() {
        let maxInterval = 0.1 //seconds
        let sut = Throttler(seconds: maxInterval)
        var numberOfTimesThisIsExecuted = 0
        let exp = expectation(description: "must be filled once")
        var areWeDoneHere = false
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(maxInterval * 100) - 10)) {
            exp.fulfill()
            areWeDoneHere = true
        }
        let work = {
            numberOfTimesThisIsExecuted += 1
            if !areWeDoneHere {
                exp.fulfill()
            }
        }
        sut.throttle(block: work)
        wait(for: [exp], timeout: maxInterval + 0.1)
        XCTAssert(numberOfTimesThisIsExecuted == 0)
    }
}

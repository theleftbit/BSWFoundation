
import Foundation
import XCTest
import BSWFoundation

class ProgressObserverTests: XCTestCase {

    func testProgressObserving() {

        let progress = Progress(totalUnitCount: 2)
        progress.completedUnitCount = 0

        var expectation1: XCTestExpectation?
        var expectation2: XCTestExpectation?

        var sut: ProgressObserver! = ProgressObserver(progress: progress) { (progress) in
            if progress.completedUnitCount == 1 {
                expectation1?.fulfill()
            } else if progress.completedUnitCount == 2 {
                expectation2?.fulfill()
            } else {
                XCTFail()
            }
        }

        weak var weakSUT = sut

        expectation1 = expectation(description: "1")
        progress.completedUnitCount = 1
        waitForExpectations(timeout: 100, handler: nil)

        expectation2 = expectation(description: "2")
        progress.completedUnitCount = 2
        waitForExpectations(timeout: 100, handler: nil)

        sut = nil

        XCTAssertNil(weakSUT) //This is to test that it is indeed dealloc
    }
}


import XCTest
@testable import BSWFoundation

class CollectionTests: XCTestCase {

    fileprivate let sample = [1,2,3]

    func testFind() {
        XCTAssertNotNil(sample.find(predicate: {$0 == 1}))
        XCTAssertNil(sample.find(predicate: {$0 == 4}))
    }

    func testSafe() {
        XCTAssertNotNil(sample[safe: 0])
        XCTAssertNil(sample[safe: 10])
    }

    func testShuffle() {
        XCTAssert(sample.shuffled() != sample)
        XCTAssert([0].shuffled() == [0])
        XCTAssert(sample.randomElement != 0)
    }

    func testMoveItem() {
        var mutableSample = sample
        mutableSample.moveItem(fromIndex: 0, toIndex: 1)
        XCTAssert(mutableSample[0] == 2)
        XCTAssert(mutableSample[1] == 1)
    }

    func testDictionaryInitWithTuples() {
        let tuples = [(0, 1), (1, 1), (2, 1), (3, 1)]
        let dict = Dictionary(elements: tuples)
        XCTAssertNotNil(dict[0])
        XCTAssertNotNil(dict[1])
        XCTAssertNotNil(dict[2])
        XCTAssertNotNil(dict[3])
        XCTAssertNil(dict[42])
    }
}

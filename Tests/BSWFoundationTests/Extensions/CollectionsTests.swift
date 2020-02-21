
import XCTest
import BSWFoundation

class CollectionTests: XCTestCase {

    fileprivate let sample = [1,2,3,4,5,6,7,8,9]

    func testFind() {
        XCTAssertNotNil(sample.find(predicate: {$0 == 1}))
        XCTAssertNil(sample.find(predicate: {$0 == 42}))
    }

    func testSafe() {
        XCTAssertNotNil(sample[safe: 0])
        XCTAssertNil(sample[safe: 42])
    }

    func testShuffle() {
        //These tests are testing for randomness, let's try up to 10 times if any of them fails
        for _ in 0...10 {
            let testShuffledArrayChanges = sample.shuffled() != sample
            let testShuffledEmptyArrayDoesntChange = [0].shuffled() == [0]
            let testRandomElement = sample.randomElement != 0
            if testShuffledArrayChanges && testShuffledEmptyArrayDoesntChange && testRandomElement {
                return
            }
        }
        XCTFail()
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
    
    func testSelectableArray() {
        let values = [0,1,2,3]
        var array = SelectableArray<Int>(options: values)
        array.select(atIndex: 2)
        XCTAssert(array.selectedElement == 2)
        array.enumerated().forEach { (offset, _) in
            XCTAssert(array[offset] == values[offset])
        }
        array.appendOption(4, andSelectIt: true)
        XCTAssert(array.selectedElement == 4)
    }
    
    func testSelectableArrayImmutable() {
        let values = [0,1,2,3]
        let array = SelectableArray<Int>(options: values)
        let newArray = array.appendingOption(4, andSelectIt: true)
        XCTAssert(newArray.selectedElement == 4)
    }

    func testSelectableArrayEquatable() {
        let array1 = SelectableArray<Int>(options: [0,1,2,3])
        let array2 = SelectableArray<Int>(options: [4,1,2,3])
        XCTAssert(array1 != array2)
    }
    
    func testSelectableArrayEquatable2() {
        var array1 = SelectableArray<Int>(options: [0,1,2,3])
        array1.select(atIndex: 0)
        let array2 = SelectableArray<Int>(options: [0,1,2,3])
        XCTAssert(array1 != array2)
    }
    
    func testRemoveSelectionSelectableArray() {
        var array1 = SelectableArray<Int>(options: [0,1,2,3])
        array1.select(atIndex: 0)
        array1.removeSelection()
        XCTAssertNil(array1.selectedElement)
    }
}

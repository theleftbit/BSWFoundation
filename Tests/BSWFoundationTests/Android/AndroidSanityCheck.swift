#if os(Android)

import BSWFoundation
import XCTest

class SomeTest: XCTestCase {
    func testSomeStuff() {
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
}

#endif

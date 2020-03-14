
#if canImport(XCTest)

import SnapshotTesting
import Foundation
import XCTest

public extension XCTestCase {
    func verify(urlRequest: URLRequest, file: StaticString = #file, testName: String = #function) {
        assertSnapshot(matching: urlRequest, as: .curl, file: file, testName: testName)
    }
}

#endif

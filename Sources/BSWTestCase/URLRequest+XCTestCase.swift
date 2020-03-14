
#if canImport(XCTest)

import SnapshotTesting
import Foundation
import XCTest

public extension XCTestCase {
    func verify(urlRequest: URLRequest) {
        assertSnapshot(matching: urlRequest, as: .curl)
    }
}

#endif

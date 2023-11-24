#if os(Android)
#else

import XCTest
import BSWFoundation

class StringTests: XCTestCase {
    
    func testSHA256() {
        let value = "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
        let signedValue = value.hmac(algorithm: .SHA256, key: "044a7bc2")
        XCTAssert(signedValue == "f92828d6b9b252f5944835a9e52d1d4ca81ff86abc4a20ffccb618da77cc5b9f")
    }

    func testCapitalize() {
        XCTAssert("hola".capitalizeFirst == "Hola")
    }

}
#endif

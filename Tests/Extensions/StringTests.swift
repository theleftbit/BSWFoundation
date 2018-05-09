
import XCTest
import BSWFoundation

class StringTests: XCTestCase {
    
    func testSHA256() {
        let value: NSString = "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
        let signedValue = value.sha256(withKey: "044a7bc2")
        XCTAssert(signedValue == "+Sgo1rmyUvWUSDWp5S0dTKgf+Gq8SiD/zLYY2nfMW58=")
    }

    func testCapitalize() {
        XCTAssert("hola".capitalizeFirst == "Hola")
    }

}

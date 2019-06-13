import XCTest
import BSWFoundation

class UserDefaultsBackedTests: XCTestCase {

    func testItStoresItInUserDefaults() {
        class Mock {
            @UserDefaultsBacked(key: "Hello") var someValue: Int?
            deinit {
                $someValue.reset()
            }
        }
        
        var sut: Mock! = Mock()
        sut.someValue = 8
        
        guard let value = UserDefaults.standard.object(forKey: "Hello") as? Int else {
            XCTFail()
            return
        }
        XCTAssert(value == 8)
        sut = nil
        XCTAssertNil(UserDefaults.standard.object(forKey: "Hello") as? Int)
    }
}

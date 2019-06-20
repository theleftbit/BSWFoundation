import XCTest
import BSWFoundation

class UserDefaultsBackedTests: XCTestCase {

    func testItStoresStrings() {
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

    func testItStoresBool() {
        class Mock {
            @UserDefaultsBacked(key: "Hello") var someValue: Bool?
            deinit {
                $someValue.reset()
            }
        }
        
        var sut: Mock! = Mock()
        sut.someValue = true
        
        guard let value = UserDefaults.standard.object(forKey: "Hello") as? Bool else {
            XCTFail()
            return
        }
        XCTAssert(value == true)
        sut = nil
        XCTAssertNil(UserDefaults.standard.object(forKey: "Hello") as? Bool)
    }

    func testItStoresDefaultValue() {
        class Mock {
            @UserDefaultsBacked(key: "Hello", defaultValue: "FuckMe") var someValue: String?
            deinit {
                $someValue.reset()
            }
        }
        
        let sut = Mock()

        guard let value = sut.someValue else {
            XCTFail()
            return
        }
        XCTAssert(value == "FuckMe")
    }
}

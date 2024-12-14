
import Foundation
import BSWFoundation

#if os(Android)
import XCTest

class UserDefaultsBackedTests: XCTestCase {

    func testItStoresStrings() {
        class Mock {
            @UserDefaultsBacked(key: "Hello") var someValue: Int?
            deinit {
                _someValue.reset()
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
                _someValue.reset()
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
                _someValue.reset()
            }
        }
        
        let sut = Mock()

        guard let value = sut.someValue else {
            XCTFail()
            return
        }
        XCTAssert(value == "FuckMe")
    }
    
    func testItStoresCodable() {
        struct SomeData: Codable {
            let id: String
        }
        class Mock {
            
            @CodableUserDefaultsBacked(key: "Hello")
            var someValue: SomeData?
            
            init() {
                someValue = .init(id: "it's me")
            }
            deinit {
                _someValue.reset()
            }
        }
        
        var sut: Mock! = Mock()
        XCTAssertNotNil(sut.someValue)
        
        guard let data = UserDefaults.standard.data(forKey: "Hello") else {
            XCTFail()
            return
        }
        XCTAssertNotNil(data)
        sut = nil
        XCTAssertNil(UserDefaults.standard.data(forKey: "Hello"))
    }
}

#else
import Testing

@Suite(.serialized)
actor UserDefaultsBackedTests {
    
    @Test
    func itStoresStrings() {
        class Mock {
            @UserDefaultsBacked(key: UserDefaultsKey) var someValue: Int?
            deinit {
                _someValue.reset()
            }
        }
        
        var sut: Mock! = Mock()
        sut.someValue = 8
        
        guard let value = UserDefaults.standard.object(forKey: UserDefaultsKey) as? Int else {
            Issue.record("Failed to retrieve the stored Int value")
            return
        }
        #expect(value == 8)
        sut = nil
        #expect(UserDefaults.standard.object(forKey: UserDefaultsKey) as? Int == nil)
    }

    @Test
    func itStoresBool() {
        class Mock {
            @UserDefaultsBacked(key: UserDefaultsKey) var someValue: Bool?
            deinit {
                _someValue.reset()
            }
        }
        
        var sut: Mock! = Mock()
        sut.someValue = true
        
        guard let value = UserDefaults.standard.object(forKey: UserDefaultsKey) as? Bool else {
            Issue.record("Failed to retrieve the stored Bool value")
            return
        }
        #expect(value == true)
        sut = nil
        #expect(UserDefaults.standard.object(forKey: UserDefaultsKey) as? Bool == nil)
    }

    @Test
    func itStoresDefaultValue() {
        class Mock {
            @UserDefaultsBacked(key: UserDefaultsKey, defaultValue: "DefaultValue") var someValue: String?
            deinit {
                _someValue.reset()
            }
        }
        
        let sut = Mock()

        guard let value = sut.someValue else {
            Issue.record("Failed to retrieve the default String value")
            return
        }
        #expect(value == "DefaultValue")
    }
    
    @Test
    func itStoresCodable() {
        struct SomeData: Codable {
            let id: String
        }
        class Mock {
            @CodableUserDefaultsBacked(key: UserDefaultsKey)
            var someValue: SomeData?
            
            init() {
                someValue = .init(id: "it's me")
            }
            deinit {
                _someValue.reset()
            }
        }
        
        var sut: Mock! = Mock()
        #expect(sut.someValue != nil)
        
        guard let data = UserDefaults.standard.data(forKey: UserDefaultsKey) else {
            Issue.record("Failed to retrieve the stored Codable value")
            return
        }
        #expect(data != nil)
        sut = nil
        #expect(UserDefaults.standard.data(forKey: UserDefaultsKey) == nil)
    }
}
#endif
private let UserDefaultsKey = "Key"

#if canImport(Testing)

import Testing
import Foundation
import BSWFoundation

actor UserDefaultsBackedTests {

    @Test
    func itStoresInts() {
        class Mock {
            @UserDefaultsBacked(key: UserDefaultsBackedTests.ItStoresIntsKey)
            var someValue: Int?
            deinit {
                _someValue.reset()
            }
        }
        
        var sut: Mock! = Mock()
        sut.someValue = 8
        
        guard let value = UserDefaults.standard.object(forKey: UserDefaultsBackedTests.ItStoresIntsKey) as? Int else {
            Issue.record("Failed to retrieve the stored Int value")
            return
        }
        #expect(value == 8)
        sut = nil
        #expect(UserDefaults.standard.object(forKey: UserDefaultsBackedTests.ItStoresIntsKey) as? Int == nil)
    }

    @Test
    func itStoresBool() {
        class Mock {
            @UserDefaultsBacked(key: UserDefaultsBackedTests.ItStoresBoolKey)
            var someValue: Bool?
            deinit {
                _someValue.reset()
            }
        }
        
        var sut: Mock! = Mock()
        sut.someValue = true
        
        guard let value = UserDefaults.standard.object(forKey: UserDefaultsBackedTests.ItStoresBoolKey) as? Bool else {
            Issue.record("Failed to retrieve the stored Bool value")
            return
        }
        #expect(value == true)
        sut = nil
        #expect(UserDefaults.standard.object(forKey: UserDefaultsBackedTests.ItStoresBoolKey) as? Bool == nil)
    }

    @Test
    func itStoresDefaultValue() {
        class Mock {
            @UserDefaultsBacked(key: UserDefaultsBackedTests.ItStoresDefaultValue, defaultValue: "DefaultValue")
            var someValue: String?
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
            @CodableUserDefaultsBacked(key: UserDefaultsBackedTests.ItStoresCodable)
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
        
        guard let data = UserDefaults.standard.data(forKey: UserDefaultsBackedTests.ItStoresCodable) else {
            Issue.record("Failed to retrieve the stored Codable value")
            return
        }
        #expect(data != nil)
        sut = nil
        #expect(UserDefaults.standard.data(forKey: UserDefaultsBackedTests.ItStoresCodable) == nil)
    }
    
    /// Since all of these tests are attacking the same UserDefaults instance,
    /// we need different keys in order for them to run concurrently
    static let ItStoresIntsKey          = "ItStoresIntsKey"
    static let ItStoresBoolKey          = "ItStoresBoolKey"
    static let ItStoresDefaultValue     = "ItStoresDefaultValue"
    static let ItStoresCodable          = "ItStoresCodable"
}

#endif

import BSWFoundation
import Dependencies
import DependenciesTestSupport
import Foundation
import Testing

@Suite(.dependencies { $0.bswKeychain = .inMemory() })
struct KeychainBackedTests {
    @Test
    func storesStringsAndRemovesNil() {
        let model = KeychainModel()
        let other = KeychainModel()
        #expect(model.token == nil)
        model.token = "secret"
        #expect(other.token == "secret")
        model.token = nil
        #expect(other.token == nil)
    }

    @Test
    func resetsAndSeparatesAccessGroups() {
        let standard = KeychainBacked(key: "token")
        let group = KeychainBacked(key: "token", appGroupID: "group.one")
        let otherGroup = KeychainBacked(key: "token", appGroupID: "group.two")
        standard.wrappedValue = "standard"
        group.wrappedValue = "shared"
        #expect(standard.wrappedValue == "standard")
        #expect(group.wrappedValue == "shared")
        #expect(otherGroup.wrappedValue == nil)
        group.reset()
        #expect(group.wrappedValue == nil)
        #expect(standard.wrappedValue == "standard")
    }

    @Test
    func forwardsServiceAndAccessGroup() {
        let memory = KeychainClient.inMemory()
        withDependencies {
            $0.bswKeychain = KeychainClient { service, accessGroup in
                #expect(service == nil)
                #expect(accessGroup == "group.test")
                return memory.store(service, accessGroup)
            }
        } operation: {
            let wrapper = KeychainBacked(key: "token", appGroupID: "group.test")
            wrapper.wrappedValue = "secret"
            #expect(memory.store(nil, "group.test").read("token") == "secret")
        }
    }
}

@Suite(.dependencies { $0.bswKeychain = .inMemory() })
struct CodableKeychainBackedTests {
    @Test
    func storesJSON() throws {
        let model = KeychainModel()
        let other = KeychainModel()
        #expect(model.record == nil)
        model.record = .init(id: "saved")
        #expect(other.record == .init(id: "saved"))
        @Dependency(\.bswKeychain) var client
        let json = try #require(client.store(nil, nil).read("record"))
        #expect(try JSONDecoder().decode(PersistenceRecord.self, from: Data(json.utf8)) == .init(id: "saved"))
    }

    @Test
    func nilAndResetPreservePlatformEncoding() {
        let wrapper = CodableKeychainBacked<PersistenceRecord>(key: "record")
        wrapper.wrappedValue = .init(id: "saved")
        wrapper.wrappedValue = nil
        #expect(wrapper.wrappedValue == nil)
        @Dependency(\.bswKeychain) var client
        #if os(anyAppleOS)
        // The existing Apple implementation encodes Optional.none as JSON null.
        #expect(client.store(nil, nil).read("record") == "null")
        #else
        #expect(client.store(nil, nil).read("record") == nil)
        #endif
        wrapper.wrappedValue = .init(id: "again")
        wrapper.reset()
        #expect(wrapper.wrappedValue == nil)
    }

    @Test
    func corruptJSONReturnsNil() {
        @Dependency(\.bswKeychain) var client
        client.store(nil, nil).set("invalid", "record")
        #expect(KeychainModel().record == nil)
    }

    @Test
    func encodingFailureRemovesValue() {
        @Dependency(\.bswKeychain) var client
        client.store(nil, nil).set("old", "record")
        let wrapper = CodableKeychainBacked<UnencodableRecord>(key: "record")
        wrapper.wrappedValue = .init()
        #expect(client.store(nil, nil).read("record") == nil)
    }
}

private final class KeychainModel {
    @KeychainBacked(key: "token") var token: String?
    @CodableKeychainBacked(key: "record") var record: PersistenceRecord?
}

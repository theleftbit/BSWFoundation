import BSWFoundation
import Dependencies
import DependenciesTestSupport
import Foundation
import Testing

@Suite(.dependencies { $0.bswUserDefaults = .inMemory() })
struct UserDefaultsBackedTests {
    @Test
    func storesStringsAndBools() {
        let model = DefaultsModel()
        let other = DefaultsModel()
        #expect(model.name == "Guest")
        #expect(model.enabled == nil)
        model.name = "Blob"
        model.enabled = true
        #expect(other.name == "Blob")
        #expect(other.enabled == true)
        model.name = nil
        model.enabled = nil
        #expect(other.name == "Guest")
        #expect(other.enabled == nil)
    }

    @Test
    func resetsToDefault() {
        let model = DefaultsModel()
        model.name = "Blob"
        model.reset()
        #expect(model.name == "Guest")
    }

    @Test
    func separatesAppGroups() {
        let standard = UserDefaultsBacked<String>(key: "shared-key")
        let group = UserDefaultsBacked<String>(key: "shared-key", appGroupID: "group.one")
        let otherGroup = UserDefaultsBacked<String>(key: "shared-key", appGroupID: "group.two")
        standard.wrappedValue = "standard"
        group.wrappedValue = "group"
        #expect(standard.wrappedValue == "standard")
        #expect(group.wrappedValue == "group")
        #expect(otherGroup.wrappedValue == nil)
    }

    @Test
    func wrongTypeReturnsDefault() {
        @Dependency(\.bswUserDefaults) var client
        client.store(nil).set(Data(), "name")
        #expect(DefaultsModel().name == "Guest")
    }

    @Test
    func forwardsSuiteAndSynchronization() {
        let memory = UserDefaultsClient.inMemory()
        let synchronized = LockIsolated(0)
        withDependencies {
            $0.bswUserDefaults = UserDefaultsClient { suite in
                #expect(suite == "group.test")
                var store = memory.store(suite)
                store.synchronize = { synchronized.withValue { $0 += 1 } }
                return store
            }
        } operation: {
            let wrapper = UserDefaultsBacked<String>(key: "key", appGroupID: "group.test")
            wrapper.wrappedValue = "value"
            wrapper.wrappedValue = nil
            wrapper.reset()
            #expect(synchronized.value == 2)
            #expect(memory.store("group.test").read("key", String.self) == nil)
        }
    }

    #if os(anyAppleOS)
    @Test
    func liveClientUsesRequestedSuite() {
        let suite = "BSWFoundationTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        withDependencies {
            $0.bswUserDefaults = .live
        } operation: {
            let wrapper = UserDefaultsBacked<Int>(key: "number", appGroupID: suite)
            wrapper.wrappedValue = 8
            #expect(defaults.integer(forKey: "number") == 8)
            wrapper.reset()
            #expect(defaults.object(forKey: "number") == nil)
            let codable = CodableUserDefaultsBacked<PersistenceRecord>(key: "record", appGroupID: suite)
            codable.wrappedValue = .init(id: "live")
            #expect(defaults.data(forKey: "record") != nil)
            #expect(codable.wrappedValue == .init(id: "live"))
            codable.wrappedValue = nil
            #expect(defaults.object(forKey: "record") == nil)
        }
    }
    #endif
}

@Suite(.dependencies { $0.bswUserDefaults = .inMemory() })
struct CodableUserDefaultsBackedTests {
    @Test
    func storesJSONAndRemovesNil() throws {
        let model = DefaultsModel()
        let other = DefaultsModel()
        #expect(model.record == .init(id: "default"))
        model.record = .init(id: "saved")
        #expect(other.record == .init(id: "saved"))
        @Dependency(\.bswUserDefaults) var client
        let data = try #require(client.store(nil).read("record", Data.self) as? Data)
        #expect(try JSONDecoder().decode(PersistenceRecord.self, from: data) == .init(id: "saved"))
        model.record = nil
        #expect(client.store(nil).read("record", Data.self) == nil)
        #expect(other.record == .init(id: "default"))
    }

    @Test
    func resetAndSuiteIsolation() {
        let standard = CodableUserDefaultsBacked<PersistenceRecord>(key: "record")
        let group = CodableUserDefaultsBacked<PersistenceRecord>(key: "record", appGroupID: "group.test")
        group.wrappedValue = .init(id: "group")
        #expect(standard.wrappedValue == nil)
        #expect(group.wrappedValue == .init(id: "group"))
        group.reset()
        #expect(group.wrappedValue == nil)
    }

    @Test
    func corruptJSONReturnsNil() {
        @Dependency(\.bswUserDefaults) var client
        client.store(nil).set(Data("invalid".utf8), "record")
        #expect(DefaultsModel().record == nil)
    }

    @Test
    func encodingFailureRemovesValue() {
        @Dependency(\.bswUserDefaults) var client
        client.store(nil).set(Data("old".utf8), "record")
        let wrapper = CodableUserDefaultsBacked<UnencodableRecord>(key: "record")
        wrapper.wrappedValue = .init()
        #expect(client.store(nil).read("record", Data.self) == nil)
    }
}

private final class DefaultsModel {
    @UserDefaultsBacked(key: "name", defaultValue: "Guest") var name: String?
    @UserDefaultsBacked(key: "enabled") var enabled: Bool?
    @CodableUserDefaultsBacked(key: "record", defaultValue: PersistenceRecord(id: "default"))
    var record: PersistenceRecord?

    func reset() { _name.reset() }
}

struct PersistenceRecord: Codable, Sendable, Equatable {
    let id: String
}

struct UnencodableRecord: Codable, Sendable {
    func encode(to encoder: any Encoder) throws {
        throw EncodingError.invalidValue(
            self, .init(codingPath: encoder.codingPath, debugDescription: "Intentional test failure")
        )
    }
}

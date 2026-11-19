import BSWFoundation
import Dependencies
import DependenciesTestSupport
import Foundation
import Testing

@Suite(.dependencies {
    $0.bswUserDefaults = .inMemory()
    $0.bswKeychain = .inMemory()
})
struct PersistenceClientTests {
    @Test
    func wrappersRetainTheirOriginalStores() {
        let model = AllStorageModel()
        model.set("outer")
        withDependencies {
            $0.bswUserDefaults = .inMemory()
            $0.bswKeychain = .inMemory()
        } operation: {
            let inner = AllStorageModel()
            #expect(inner.values == [nil, nil, nil, nil])
            inner.set("inner")
            #expect(model.values == ["outer", "outer", "outer", "outer"])
        }
        let escaped = withDependencies {
            $0.bswUserDefaults = .inMemory()
            $0.bswKeychain = .inMemory()
        } operation: {
            let model = AllStorageModel()
            model.set("escaped")
            return model
        }
        #expect(escaped.values == ["escaped", "escaped", "escaped", "escaped"])
        escaped.set("updated")
        #expect(escaped.values == ["updated", "updated", "updated", "updated"])
        #expect(model.values == ["outer", "outer", "outer", "outer"])
    }

    @Test
    func isolatesConcurrentScopes() async {
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<20 {
                group.addTask {
                    await withDependencies {
                        $0.bswUserDefaults = .inMemory()
                        $0.bswKeychain = .inMemory()
                    } operation: {
                        let model = AllStorageModel()
                        #expect(model.values == [nil, nil, nil, nil])
                        let value = "\(index)"
                        model.set(value)
                        await Task.yield()
                        #expect(model.values == [value, value, value, value])
                    }
                }
            }
        }
    }

    @Test
    func concurrentAccessToOneClient() async {
        @Dependency(\.bswUserDefaults) var defaults
        @Dependency(\.bswKeychain) var keychain
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<50 {
                group.addTask { [defaults = defaults, keychain = keychain] in
                    let key = "\(index)"
                    defaults.store(nil).set(key, key)
                    keychain.store(nil, nil).set(key, key)
                    await Task.yield()
                    #expect(defaults.store(nil).read(key, String.self) as? String == key)
                    #expect(keychain.store(nil, nil).read(key) == key)
                }
            }
        }
    }

    @Test
    func inMemoryKeychainsSeparateServicesAndGroups() {
        let client = KeychainClient.inMemory()
        client.store("one", nil).set("one", "key")
        client.store("one", "group").set("group", "key")
        #expect(client.store("one", nil).read("key") == "one")
        #expect(client.store("one", "group").read("key") == "group")
        #expect(client.store("two", nil).read("key") == nil)
        #expect(client.store(nil, nil).read("key") == nil)
    }

    @Test
    func separateClientInstancesHaveSeparateStorage() {
        let firstDefaults = UserDefaultsClient.inMemory()
        firstDefaults.store(nil).set("first", "key")
        #expect(UserDefaultsClient.inMemory().store(nil).read("key", String.self) == nil)
        let firstKeychain = KeychainClient.inMemory()
        firstKeychain.store(nil, nil).set("first", "key")
        #expect(KeychainClient.inMemory().store(nil, nil).read("key") == nil)
    }

    #if DEBUG
    @Test
    func missingOverrideReportsIssueWithoutAccessingLiveStorage() {
        var defaults: UserDefaultsBacked<String>?
        withKnownIssue {
            defaults = withDependencies {
                $0 = DependencyValues()
                $0.context = .test
            } operation: {
                let wrapper = UserDefaultsBacked<String>(key: "BSWFoundation.unconfigured")
                wrapper.wrappedValue = "memory only"
                return wrapper
            }
        }
        #expect(defaults?.wrappedValue == "memory only")
        var keychain: KeychainBacked?
        withKnownIssue {
            keychain = withDependencies {
                $0 = DependencyValues()
                $0.context = .test
            } operation: {
                let wrapper = KeychainBacked(key: "BSWFoundation.unconfigured")
                wrapper.wrappedValue = "memory only"
                return wrapper
            }
        }
        #expect(keychain?.wrappedValue == "memory only")
    }
    #endif
}

private final class AllStorageModel {
    @UserDefaultsBacked(key: "value") var defaults: String?
    @CodableUserDefaultsBacked(key: "value-codable") var codableDefaults: String?
    @KeychainBacked(key: "value") var keychain: String?
    @CodableKeychainBacked(key: "value-codable") var codableKeychain: String?

    var values: [String?] { [defaults, codableDefaults, keychain, codableKeychain] }

    func set(_ value: String) {
        defaults = value
        codableDefaults = value
        keychain = value
        codableKeychain = value
    }
}

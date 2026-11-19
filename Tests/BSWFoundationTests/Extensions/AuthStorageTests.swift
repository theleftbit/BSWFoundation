#if os(anyAppleOS)
import BSWFoundation
import Dependencies
import DependenciesTestSupport
import Foundation
import Testing

@Suite(.dependencies {
    $0.bswUserDefaults = .inMemory()
    $0.bswKeychain = .inMemory()
})
struct AuthStorageTests {
    @Test
    func firstLaunchClearsOnlyAuthKeysAndRecordsExecution() {
        @Dependency(\.bswUserDefaults) var defaults
        @Dependency(\.bswKeychain) var keychain
        let store = keychain.store(nil, nil)
        for key in authKeys { store.set("old", key) }
        store.set("keep", "unrelated")

        let storage = AuthStorage()
        #expect(storage.jwtToken == nil)
        #expect(storage.userID == nil)
        #expect(storage.authToken == nil)
        #expect(storage.refreshToken == nil)
        #expect(store.read("unrelated") == "keep")
        #expect(defaults.store(nil).read("HasAppBeenExecuted", Bool.self) as? Bool == true)
    }

    @Test
    func subsequentInstancesPreserveTokens() {
        let storage = AuthStorage()
        storage.jwtToken = "jwt"
        storage.userID = "user"
        storage.authToken = "auth"
        storage.refreshToken = "refresh"

        let other = AuthStorage()
        #expect(other.jwtToken == "jwt")
        #expect(other.userID == "user")
        #expect(other.authToken == "auth")
        #expect(other.refreshToken == "refresh")
        other.authToken = nil
        #expect(storage.authToken == nil)
    }

    @Test
    func previouslyExecutedInstallDoesNotClearPreloadedTokens() {
        @Dependency(\.bswUserDefaults) var defaults
        @Dependency(\.bswKeychain) var keychain
        defaults.store(nil).set(true, "HasAppBeenExecuted")
        for key in authKeys { keychain.store(nil, nil).set("preloaded", key) }
        let storage = AuthStorage()
        #expect(storage.jwtToken == "preloaded")
        #expect(storage.userID == "preloaded")
        #expect(storage.authToken == "preloaded")
        #expect(storage.refreshToken == "preloaded")
    }

    @Test
    func reinstallClearsTokensAgain() {
        let storage = AuthStorage()
        storage.authToken = "previous-install"
        @Dependency(\.bswUserDefaults) var defaults
        defaults.store(nil).remove("HasAppBeenExecuted")
        #expect(AuthStorage().authToken == nil)
        #expect(storage.authToken == nil)
    }

    @Test(arguments: ["YES", "true", "1"])
    func executionFlagKeepsUserDefaultsBoolCoercion(_ flag: String) {
        @Dependency(\.bswUserDefaults) var defaults
        @Dependency(\.bswKeychain) var keychain
        defaults.store(nil).set(flag, "HasAppBeenExecuted")
        keychain.store(nil, nil).set("keep", "AuthToken")
        #expect(AuthStorage().authToken == "keep")
    }

    @Test
    func liveExecutionFlagUsesBoolGetter() {
        let suite = "BSWFoundationTests.Auth.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("YES", forKey: "HasAppBeenExecuted")
        @Dependency(\.bswKeychain) var keychain
        keychain.store(nil, nil).set("keep", "AuthToken")
        let store = UserDefaultsClient.live.store(suite)
        withDependencies {
            $0.bswUserDefaults = UserDefaultsClient { _ in store }
        } operation: {
            #expect(AuthStorage().authToken == "keep")
        }
    }

    @Test
    func appGroupPreservesTokensAndDoesNotRecordExecution() {
        @Dependency(\.bswUserDefaults) var defaults
        @Dependency(\.bswKeychain) var keychain
        let store = keychain.store("SharedApp", "group.test")
        for key in authKeys { store.set("shared", key) }
        let storage = AuthStorage(style: .appGroup(id: "group.test", appName: "SharedApp"))
        #expect(storage.jwtToken == "shared")
        #expect(storage.userID == "shared")
        #expect(storage.authToken == "shared")
        #expect(storage.refreshToken == "shared")
        #expect(defaults.store(nil).read("HasAppBeenExecuted", Bool.self) == nil)

        // A later first launch of simple storage does not clear the shared service.
        _ = AuthStorage()
        #expect(storage.authToken == "shared")
    }

    @Test
    func separatesServicesAndAccessGroups() {
        let first = AuthStorage(style: .appGroup(id: "group.one", appName: "App"))
        let same = AuthStorage(style: .appGroup(id: "group.one", appName: "App"))
        let otherGroup = AuthStorage(style: .appGroup(id: "group.two", appName: "App"))
        let otherApp = AuthStorage(style: .appGroup(id: "group.one", appName: "Other"))
        first.authToken = "shared"
        #expect(same.authToken == "shared")
        #expect(otherGroup.authToken == nil)
        #expect(otherApp.authToken == nil)
    }

    @Test
    func clearsOnlyThisStorageNamespace() {
        let storage = AuthStorage()
        storage.jwtToken = "jwt"
        storage.userID = "user"
        storage.authToken = "auth"
        storage.refreshToken = "refresh"
        let shared = AuthStorage(style: .appGroup(id: "group.test", appName: "SharedApp"))
        shared.authToken = "keep"
        storage.clearKeychain()
        #expect(storage.jwtToken == nil)
        #expect(storage.userID == nil)
        #expect(storage.authToken == nil)
        #expect(storage.refreshToken == nil)
        #expect(shared.authToken == "keep")
        @Dependency(\.bswUserDefaults) var defaults
        #expect(defaults.store(nil).read("HasAppBeenExecuted", Bool.self) as? Bool == true)
    }

    @Test
    func sharesDefaultServiceWithKeychainWrappers() {
        let storage = AuthStorage()
        let token = KeychainBacked(key: "AuthToken")
        storage.authToken = "storage"
        #expect(token.wrappedValue == "storage")
        token.wrappedValue = "wrapper"
        #expect(storage.authToken == "wrapper")
    }

    @Test
    func capturesStoresAtInitialization() {
        let storage = withDependencies {
            $0.bswUserDefaults = .inMemory()
            $0.bswKeychain = .inMemory()
        } operation: {
            let storage = AuthStorage()
            storage.authToken = "scoped"
            return storage
        }
        #expect(storage.authToken == "scoped")
        let other = AuthStorage()
        #expect(other.authToken == nil)
        storage.authToken = "updated"
        #expect(storage.authToken == "updated")
        #expect(other.authToken == nil)
    }

    @Test
    func isolatesConcurrentAuthStorage() async {
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<20 {
                group.addTask {
                    await withDependencies {
                        $0.bswUserDefaults = .inMemory()
                        $0.bswKeychain = .inMemory()
                    } operation: {
                        let storage = AuthStorage()
                        #expect(storage.authToken == nil)
                        storage.authToken = "\(index)"
                        await Task.yield()
                        #expect(AuthStorage().authToken == "\(index)")
                    }
                }
            }
        }
    }

    @Test
    func tokenExpirationKeepsExistingBehavior() throws {
        let storage = AuthStorage()
        #expect(storage.tokenIsExpired == false)
        storage.jwtToken = "malformed"
        #expect(storage.tokenIsExpired == false)
        storage.jwtToken = try jwt(body: [:])
        #expect(storage.tokenIsExpired == false)
        storage.jwtToken = try jwt(body: ["exp": 0])
        #expect(storage.tokenIsExpired == true)
        storage.jwtToken = try jwt(body: ["exp": 32_503_680_000]) // Year 3000.
        #expect(storage.tokenIsExpired == false)
    }

    private var authKeys: [String] { ["JWT", "UserID", "AuthToken", "RefreshToken"] }

    private func jwt(body: [String: Int]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: body)
        let payload = data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "e30.\(payload).signature"
    }
}
#endif

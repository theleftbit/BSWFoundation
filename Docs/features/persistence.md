# Persistence And JWT

Persistence helpers provide small wrappers around Keychain and UserDefaults behavior commonly needed by app targets.

## AuthStorage

`AuthStorage` is a AppleOS-only keychain-backed token store. It supports a default simple style and an app-group style for shared containers.

Stored values include:

- JWT token
- User ID
- Auth token
- Refresh token

The simple style clears the keychain on first execution after install so deleting and reinstalling an app does not silently preserve auth state.

`tokenIsExpired` decodes the stored JWT and checks the `exp` claim. If there is no stored or decodable JWT, it returns `false`.

## JWT Helpers

The same source file includes JWT decoding helpers derived from Auth0's JWT decoder. Because they are co-located in `AuthStorage.swift`, they currently compile with the file's AppleOS guard.

- `decode(jwt:)` decodes a token into a `JWT`.
- `JWT` exposes header, body, signature and standard claims.
- `Claim` offers typed accessors for strings, numbers, dates and string arrays.
- `DecodeError` reports malformed JWT parts, base64url payloads and JSON.
- `AuthStorage.extractBodyFromJWT(_:)` returns the decoded body dictionary when possible.

## KeychainBacked

`KeychainBacked` stores optional strings in Keychain. It supports AppleOS through `KeychainAccess` and Android through `SkipKeychain`; Linux is excluded.

`CodableKeychainBacked` stores optional `Codable` values by encoding them before persistence and decoding them on read.

The existing nil behavior is preserved: `KeychainBacked` removes its entry on nil or reset. `CodableKeychainBacked` encodes nil as JSON `null` on Apple platforms and removes the entry on Android. Both read back as nil. Encoding failures remove the entry; decoding failures return nil.

## UserDefaultsBacked

`UserDefaultsBacked` stores optional primitive values in user defaults. AppleOS can use standard defaults or an app group suite. The Android path currently supports a narrower set of value types.

`CodableUserDefaultsBacked` stores optional `Codable` values by encoding them into user defaults.

Nil and reset remove defaults entries. Missing or incorrectly typed primitive values return the configured default. Missing Codable data returns the configured default, while malformed JSON returns nil. Encoding failures remove the entry.

## Dependency Overrides For App Tests

All four wrappers retain their existing initializers and property syntax. They capture a store from `swift-dependencies` during initialization:

- `DependencyValues.bswUserDefaults` is a `UserDefaultsClient`, shared by both defaults wrappers.
- `DependencyValues.bswKeychain` is a `KeychainClient`, shared by both keychain wrappers.

Construct the model inside the override scope. It retains that store after leaving the scope; later dependency overrides do not redirect an existing wrapper.

```swift
import BSWFoundation
import Dependencies
import Testing

final class SettingsModel {
    @UserDefaultsBacked(key: "name") var name: String?
    @KeychainBacked(key: "token") var token: String?
}

@Test func savesSettings() {
    withDependencies {
        $0.bswUserDefaults = .inMemory()
        $0.bswKeychain = .inMemory()
    } operation: {
        let model = SettingsModel()
        model.name = "Blob"
        model.token = "test-token"
        #expect(SettingsModel().token == "test-token")
    }
}
```

Each call to `.inMemory()` creates fresh, lock-protected storage. Wrappers using the same client share values within the same namespace. Defaults namespaces distinguish standard defaults and app group IDs; keychain namespaces distinguish service and access group. Create fresh clients per test instead of sharing a static client across tests.

Swift Testing apps can link `DependenciesTestSupport` to their test target and apply a suite trait, which runs the factory separately for each test:

```swift
import DependenciesTestSupport

@Suite(.dependencies {
    $0.bswUserDefaults = .inMemory()
    $0.bswKeychain = .inMemory()
})
struct SettingsTests {
    // Construct models in the test bodies.
}
```

The live defaults remain standard/app group UserDefaults on Apple and AndroidUserDefaults on Android. The live keychain remains KeychainAccess on Apple (using the bundle identifier by default) and SkipKeychain on Android. Android still uses standard/shared platform stores and ignores app group/service selection; in-memory clients provide namespace isolation on both platforms. The Android primitive defaults wrapper continues to support Bool and String; its live Bool getter returns false for a missing key, as before. Codable defaults still use Data and JSON.

Previews use in-memory storage. In debug tests, an omitted override reports a dependency issue and falls back to in-memory storage rather than touching disk or keychain. Explicitly supply fresh clients for deterministic, isolated tests. Integration tests can explicitly select `.live` and use a dedicated suite/service.

Both clients expose store factories and public closure-based `Store` types for custom fakes, call recording, and preloaded data. `UserDefaultsClient.Store.read` receives the requested Swift type so the Android implementation can select its typed getter. Custom stores must support synchronous, thread-safe access.

`AuthStorage` still directly accesses its live stores and is tracked as a follow-up to this wrapper integration.

## Maintenance Rule

Changes to persistence semantics should update this note because consuming apps may rely on reinstall behavior, app group handling and Android support boundaries.

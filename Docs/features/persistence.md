# Persistence And JWT

Persistence helpers provide small wrappers around Keychain and UserDefaults behavior commonly needed by app targets.

## AuthStorage

`AuthStorage` is a Darwin-only keychain-backed token store. It supports a default simple style and an app-group style for shared containers.

Stored values include:

- JWT token
- User ID
- Auth token
- Refresh token

The simple style clears the keychain on first execution after install so deleting and reinstalling an app does not silently preserve auth state.

`tokenIsExpired` decodes the stored JWT and checks the `exp` claim. If there is no stored or decodable JWT, it returns `false`.

## JWT Helpers

The same source file includes JWT decoding helpers derived from Auth0's JWT decoder. Because they are co-located in `AuthStorage.swift`, they currently compile with the file's Darwin guard.

- `decode(jwt:)` decodes a token into a `JWT`.
- `JWT` exposes header, body, signature and standard claims.
- `Claim` offers typed accessors for strings, numbers, dates and string arrays.
- `DecodeError` reports malformed JWT parts, base64url payloads and JSON.
- `AuthStorage.extractBodyFromJWT(_:)` returns the decoded body dictionary when possible.

## KeychainBacked

`KeychainBacked` stores optional strings in Keychain. It supports Darwin through `KeychainAccess` and Android through `SkipKeychain`; Linux and WebAssembly are excluded. Android consumers must build with `SKIP_ENABLED=1` so SwiftPM includes `SkipKeychain`.

`CodableKeychainBacked` stores optional `Codable` values by encoding them before persistence and decoding them on read. It is also unavailable on WebAssembly because browsers do not expose Keychain-equivalent secure storage to SwiftWasm.

## UserDefaultsBacked

`UserDefaultsBacked` stores optional primitive values in user defaults. Darwin can use standard defaults or an app group suite. The Android path requires Skip's user defaults bridge, which is included when building with `SKIP_ENABLED=1`, and currently supports a narrower set of value types.

`CodableUserDefaultsBacked` stores optional `Codable` values by encoding them into user defaults.

## Maintenance Rule

Changes to persistence semantics should update this note because consuming apps may rely on reinstall behavior, app group handling and Android support boundaries.

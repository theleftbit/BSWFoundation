# Module Map

## APIClient

`Sources/BSWFoundation/APIClient/` contains REST client primitives:

- `APIClient` performs requests through an injected `APIClientNetworkFetcher`.
- `Endpoint` describes method, path, parameters, headers, encoding, timeouts and file uploads.
- `Environment` owns the base URL and insecure-connection policy.
- `Router` builds `URLRequest` values and applies user agent, headers and encoding.
- `Request` wraps a typed endpoint, decoder and response validator.
- `MockNetworkFetcher` supports tests by returning configured data/status and capturing outgoing requests.

## Persistence

`Sources/BSWFoundation/AuthStorage/` and `Sources/BSWFoundation/PropertyWrappers/` contain storage helpers:

- `AuthStorage` stores auth identifiers and tokens in Keychain on Darwin.
- `KeychainBacked` wraps string keychain values.
- `CodableKeychainBacked` wraps codable keychain values.
- `UserDefaultsBacked` and `CodableUserDefaultsBacked` wrap user defaults values.
- JWT helpers decode token claims and expose expiration checks. They currently live in `AuthStorage.swift` and compile with the same Darwin guard.

## Async And Observation

`Sources/BSWFoundation/AsyncStream/` and `Sources/BSWFoundation/Extensions/Observation+Ext.swift` provide event streams and observation-to-stream helpers.

## Platform Utilities

`Sources/BSWFoundation/Extensions/` includes small additions for bundle metadata, process checks, collection helpers, string utilities, HMAC generation, throttling, progress observation and test detection.

`Sources/BSWFoundation/Location/` contains `LocationFetcher`, a CoreLocation wrapper available only on Darwin.

## Parsing

`Sources/BSWFoundation/Parse/` contains JSON parsing helpers, custom date-decoding strategy support and failable array decoding.

## Constants

`Sources/BSWFoundation/ModuleConstants.swift` contains package-level aliases and helpers such as `VoidHandler` and `submoduleName(_:)`.

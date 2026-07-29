# Platform Support

`BSWFoundation` is Apple-first and has explicit Android and browser WebAssembly paths for the subset that can run without Apple-only frameworks.

## Apple Platforms

The package declares iOS, tvOS, macOS, Mac Catalyst and watchOS support in `Package.swift`. The dependency condition also includes visionOS for Apple-only dependencies, but `visionOS` is not currently listed as a minimum package platform. Darwin-only functionality is guarded with `canImport(Darwin)` or framework availability checks.

Apple-specific areas include:

- `AuthStorage`, backed by `KeychainAccess`. The JWT decoding helpers in the same file are currently included in this Darwin-only guard.
- `LocationFetcher`, backed by CoreLocation.
- `ProgressObserver`, backed by Foundation KVO.
- `Throttler`, backed by Dispatch.
- `UIApplication.isRunningTests`, available only on iOS.
- `KeychainAccess` is used only on Apple platforms through a target dependency condition.

## Android Via Skip

When `SKIP_ENABLED` is present, the package adds Skip dependencies and Android-specific imports:

- `skip-fuse`
- `skip-keychain`
- `FoundationEssentials`
- `FoundationNetworking`
- `FoundationInternationalization`
- Android logging and platform APIs where needed.

The README states that all features except `AuthStorage` and `LocationFetcher` are intended to be available on Android. `KeychainBacked` uses `SkipKeychain` on Android when Skip dependencies are enabled. The JWT helpers currently live under the `AuthStorage.swift` Darwin guard, so their intended Android availability should be clarified before relying on them from Skip code.

## Browser WebAssembly Via SwiftWasm

The package compiles for WASI browser-hosted SwiftWasm. WASM dependencies are conditioned in `Package.swift`:

- `JavaScriptKit`
- `JavaScriptEventLoop`
- `JavaScriptFoundationCompat`
- `swift-log`

Browser networking is handled by the WASI-only fetch implementation. `APIClient` defaults to the browser fetch-backed network fetcher on WASM and keeps the URLSession-backed default on platforms where URLSession is available. Browser fetch follows browser security rules for TLS, CORS and mixed content; `Environment.shouldAllowInsecureConnections` is not emulated in the browser.

WASM consumers must install the JavaScriptKit event-loop executor once during host startup by calling `BSWBrowserRuntime.installJavaScriptEventLoop()` before creating an `APIClient` or starting async work that depends on JavaScript callbacks.

Persistence support on WASM is intentionally narrow:

- `UserDefaultsBacked` uses an internal browser `localStorage` adapter and supports only the value types documented in README. Use `CodableUserDefaultsBacked` for codable values.

Current WASM exclusions and limitations:

- `AuthStorage` and `LocationFetcher` are unavailable.
- `KeychainBacked` and `CodableKeychainBacked` are unavailable because browsers do not expose Keychain-equivalent secure storage to SwiftWasm.
- URL file uploads are unavailable; browser upload support must use the WASM browser upload body API.
- APIs that require Apple-only frameworks or URLSession delegates remain guarded out of WASI.

## Compatibility Rule

New shared APIs should compile on all declared Apple platforms unless intentionally guarded. New APIs meant to be available on Android or WASM should avoid Darwin-only dependencies or provide platform-specific branches. Public APIs that are intentionally unavailable on Android or WASM should fail clearly at compile time or with a targeted runtime diagnostic.

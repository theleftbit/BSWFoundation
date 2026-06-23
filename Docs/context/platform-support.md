# Platform Support

`BSWFoundation` is Apple-first and has an explicit Skip/Android path for the subset that can run without Apple-only frameworks.

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

## Compatibility Rule

New shared APIs should compile on all declared Apple platforms unless intentionally guarded. New APIs meant to be available on Android should avoid Darwin-only dependencies or provide Android-specific branches.

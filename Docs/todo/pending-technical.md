# Technical Pending

Last updated: 2026-06-23.

## Open Items

- Clarify the Android-supported value types for `UserDefaultsBacked` and decide whether additional primitive or `Codable` support is required.
- Keep README Android support notes aligned with compile-time guards in source files.
- Consider adding focused DocC examples for `APIClient`, persistence wrappers, JWT helpers, parsing helpers and `AsyncStreamDispatcher`.
- Review Darwin-only utilities periodically to decide whether they should stay Apple-only or gain Skip-compatible equivalents.
- Decide whether `visionOS` should be declared as a package platform or only kept in dependency conditions.
- Decide whether JWT helpers should move out of `AuthStorage.swift` if they are intended to be available on Android.

## Maintenance Triggers

Update this list when adding public APIs, changing platform support, altering request validation/retry behavior or modifying storage semantics.

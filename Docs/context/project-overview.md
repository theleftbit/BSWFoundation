# Project Overview

`BSWFoundation` is a Swift Package Manager library containing shared utilities used across TheLeftBit apps. It provides a small foundation layer for REST networking, keychain and user defaults persistence, JWT decoding, observation helpers, parsing, random utilities, common extensions and test support.

## Package Shape

- Product: `BSWFoundation`
- Main target: `Sources/BSWFoundation`
- Test target: `Tests/BSWFoundationTests`
- Swift tools version: `6.2`
- Swift language mode: `6`
- Minimum declared platforms: iOS 17, tvOS 17, macOS 15, Mac Catalyst 17 and watchOS 11

## Dependencies

- `swift-crypto` provides HMAC support in `String+Crypto`.
- `KeychainAccess` backs Darwin keychain storage.
- `skip-fuse` and `skip-keychain` are included only when `SKIP_ENABLED` is present in the environment.

## Documentation Responsibilities

Use `Docs/` for package-level context: why modules exist, which platform boundaries matter, what behavior consumers rely on and what maintenance work remains. Keep DocC comments as the source for symbol-level API details.

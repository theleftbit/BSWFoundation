# 003 - Scoped Persistence Dependencies

Date: 2026-11-19

## Status

Accepted

## Context

Consuming apps need deterministic tests for models that declare persistence property wrappers. Previously, those wrappers constructed live platform stores internally, forcing tests to use shared defaults or the real keychain.

## Decision

Use Point-Free's `swift-dependencies` to expose `bswUserDefaults` and `bswKeychain` storage factories. All four wrappers capture their resolved store at initialization while retaining existing initializers, encoding, reset behavior, and Apple/Android live backends. Public closure-based clients support custom fakes; fresh `.inMemory()` clients support isolated tests and previews. No dependency macros are required.

## Consequences

- App tests create models inside an override scope. Existing instances retain their original stores.
- Tests explicitly create fresh in-memory clients. Shared mutable clients are not automatically isolated by task-local scoping.
- Missing overrides report an issue in debug tests and use an in-memory fallback, never live persistence.
- Live Android namespace/type limitations remain unchanged; in-memory clients distinguish namespaces on both platforms.
- `AuthStorage` requires a follow-up because it directly accesses defaults/keychain and clears auth state on first launch.

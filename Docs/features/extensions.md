# Foundation Extensions

The `Extensions` folder contains focused utility APIs. Keep this area conservative: these APIs are globally visible and easy for downstream apps to depend on.

## Collections

Collection helpers include safe indexing, random element access, mutable movement, dictionary construction from key/value pairs, `find`, and `SelectableArray`.

## Strings And Crypto

String helpers cover string length, first-character capitalization, trimming newlines and HMAC generation using `swift-crypto`.

## Platform And Runtime

`Bundle` exposes display name, app version, build, OS name and OS version helpers. Android uses the device API level when compiled through Skip.

`ProcessInfo` exposes checks for Mac execution and Xcode previews.

`UIApplication.isRunningTests` is available only on iOS debug builds.

## Concurrency And Utilities

`Task.never` provides test and placeholder helpers for async code paths expected not to return.

`with(_:_:)` applies inline mutation to a value and returns it.

`Error.isURLCancelled` centralizes URL cancellation detection.

Numeric random helpers provide `UInt32.random`, `UInt64.random`, `UInt64.distance(_:)` for integer ranges and `Int.random(_:)`.

Date helpers expose millisecond or second Unix timestamps.

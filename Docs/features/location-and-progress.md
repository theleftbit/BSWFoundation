# Location And Progress

This note covers utility APIs that are intentionally Darwin-only.

## LocationFetcher

`LocationFetcher` is a `@MainActor` CoreLocation wrapper that returns the current location with async/await.

Important behavior:

- Requires `NSLocationWhenInUseUsageDescription` in the host app's Info.plist.
- Returns `lastKnownLocation` when requested and available.
- Coalesces concurrent callers through checked continuations.
- Requests authorization when status is not determined.
- Reports authorization denial and CoreLocation errors through `LocationFetcher.Error`.

## ProgressObserver

`ProgressObserver` wraps KVO observation of `Foundation.Progress.fractionCompleted` and forwards updates to a `@MainActor` callback.

## Throttler

`Throttler` delays execution of a job and cancels the previous scheduled job when a new one is submitted on the same instance.

## Platform Boundary

These utilities should remain guarded unless equivalent behavior is deliberately implemented for non-Darwin platforms.

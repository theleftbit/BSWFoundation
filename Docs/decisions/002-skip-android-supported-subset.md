# 002 - Skip Android Supported Subset

Date: 2026-06-23

## Status

Accepted

## Context

The package is Apple-first but also supports Android through Skip for shared app code. Some APIs depend on Apple frameworks and cannot be expected to run unchanged on Android.

## Decision

Android support is enabled conditionally through `SKIP_ENABLED` in `Package.swift`. Shared APIs should compile under Skip when they do not require Apple-only frameworks. Apple-only APIs remain guarded by platform checks.

Current Android exclusions documented in the README are `AuthStorage` and `LocationFetcher`.

## Consequences

- New dependencies needed only for Skip should be added conditionally.
- Darwin-only features should use explicit compile-time guards.
- Documentation must call out support differences when behavior diverges between Apple platforms and Android.

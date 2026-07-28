# 001 - Shared SwiftPM Foundation Package

Date: 2026-06-23

## Status

Accepted

## Context

TheLeftBit apps need a reusable baseline for common networking, persistence, parsing, async observation and platform utilities. Keeping these APIs in app repositories duplicates behavior and makes cross-app fixes harder.

## Decision

`BSWFoundation` remains a Swift Package Manager library that exports one library product, `BSWFoundation`, with focused modules under `Sources/BSWFoundation/`.

Package-level context lives in `Docs/`; symbol-level reference remains in DocC comments and Swift Package Index.

## Consequences

- Public API changes should be treated as shared-library changes.
- Documentation should describe package behavior and platform boundaries, not only local implementation details.
- Tests should cover utilities whose behavior is relied on by downstream applications.

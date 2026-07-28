# BSWFoundation Knowledge Base

Last updated: 2026-06-23.

This directory is the source of package context for `BSWFoundation`: shared Swift utilities, networking primitives, persistence wrappers, platform boundaries and pending technical work. Symbol-level API reference remains in DocC comments and Swift Package Index.

## Quick Start

- [Project overview](context/project-overview.md)
- [Module map](context/module-map.md)
- [Platform support](context/platform-support.md)
- [APIClient](features/api-client.md)
- [Persistence and JWT](features/persistence.md)
- [Parsing](features/parsing.md)
- [Async streams and observation](features/async-observation.md)
- [Foundation extensions](features/extensions.md)
- [Location and progress](features/location-and-progress.md)
- [Technical pending](todo/pending-technical.md)

## Decisions

- [001 - Shared SwiftPM foundation package](decisions/001-shared-swiftpm-foundation-package.md)
- [002 - Skip Android supported subset](decisions/002-skip-android-supported-subset.md)

## Systems

- Package: `BSWFoundation`
- Package manifest: `Package.swift`
- Runtime source: `Sources/BSWFoundation/`
- Tests: `Tests/BSWFoundationTests/`
- Public API docs: Swift Package Index DocC documentation

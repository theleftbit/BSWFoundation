# Graph Report - BSWFoundation  (2026-06-23)

## Corpus Check
- 65 files · ~14,838 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 547 nodes · 1004 edges · 30 communities
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 62 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7089710a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]

## God Nodes (most connected - your core abstractions)
1. `Foundation` - 36 edges
2. `APIClient` - 19 edges
3. `Task` - 18 edges
4. `Int` - 17 edges
5. `SelectableArray` - 16 edges
6. `Testing` - 15 edges
7. `BSWFoundation` - 15 edges
8. `Endpoint` - 14 edges
9. `HTTPMethod` - 14 edges
10. `APIClientTests` - 13 edges

## Surprising Connections (you probably didn't know these)
- `FailableCodableArray` --implements--> `DateDecodingStrategyProvider`  [EXTRACTED]
  Docs/features/parsing.md → Sources/BSWFoundation/Parse/JSONParser.swift
- `Network401Fetcher` --inherits--> `APIClientNetworkFetcher`  [EXTRACTED]
  Tests/BSWFoundationTests/APIClient/APIClientTests.swift → Sources/BSWFoundation/APIClient/APIClient.swift
- `BSWEnvironment` --implements--> `Environment`  [EXTRACTED]
  Tests/BSWFoundationTests/APIClient/Stubs.swift → Sources/BSWFoundation/APIClient/Environment.swift
- `Hosts` --implements--> `Environment`  [EXTRACTED]
  Tests/BSWFoundationTests/APIClient/Stubs.swift → Sources/BSWFoundation/APIClient/Environment.swift
- `SampleModelWithDate` --implements--> `DateDecodingStrategyProvider`  [EXTRACTED]
  Tests/BSWFoundationTests/Parsing/JSONParserTests.swift → Sources/BSWFoundation/Parse/JSONParser.swift

## Import Cycles
- None detected.

## Communities (30 total, 0 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.11
Nodes (12): APIClient, APIClient, Response, APIClientTests, Network401Fetcher, ValidationError, submoduleName(), Data (+4 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (31): Any, URLEncoding, base64UrlDecode(), Claim, decode(), DecodedJWT, DecodeError, invalidBase64Url (+23 more)

### Community 2 - "Community 2"
Cohesion: 0.10
Nodes (20): Behavior, all, none, onlyFailing, LoggingConfiguration, VoidResponse, MimeType, custom (+12 more)

### Community 3 - "Community 3"
Cohesion: 0.08
Nodes (18): OPTIONS, ClosedRange, Array, Collection, SelectableArray, Int, UInt32, String (+10 more)

### Community 4 - "Community 4"
Cohesion: 0.07
Nodes (15): Codable, Date, Dictionary, CollectionTests, JSONSerialization, JSONParser, CodingKeys, amount (+7 more)

### Community 5 - "Community 5"
Cohesion: 0.08
Nodes (23): RouterTests, GIF, GIFKeys, id, images, title, Giphy, Hosts (+15 more)

### Community 6 - "Community 6"
Cohesion: 0.09
Nodes (18): ApplicationWrapper, AsyncStreamDispatcher, AsyncStreamDispatcherTests, sendValue, Element, Event, AsyncStream, ProgressObserver (+10 more)

### Community 7 - "Community 7"
Cohesion: 0.08
Nodes (26): encodingRequestFailed, failureStatusCode, malformedResponse, malformedURL, CheckedContinuation, CLAuthorizationStatus, CLLocation, CLLocationManager (+18 more)

### Community 8 - "Community 8"
Cohesion: 0.09
Nodes (23): Request, Endpoint, HTTPMethod, CONNECT, DELETE, GET, HEAD, PATCH (+15 more)

### Community 9 - "Community 9"
Cohesion: 0.11
Nodes (18): Android, AndroidLogging, APIClient, APIClient, String, DateFormatter, Error, FailableCodableArray (+10 more)

### Community 10 - "Community 10"
Cohesion: 0.07
Nodes (10): APIClientErrorTests, EnvironmentTests, BSWFoundation, BundleTests, ProgressObserverTests, StringTests, TaskTests, UIApplicationTests (+2 more)

### Community 11 - "Community 11"
Cohesion: 0.11
Nodes (19): AnyObject, APIClient, APIClientNetworkFetcher, APIClient.Error, ShimError, SessionDelegate, Swift.Error, MockAPIClientDelegate (+11 more)

### Community 12 - "Community 12"
Cohesion: 0.24
Nodes (7): Crypto, CryptoAlgorithm, SHA256, SHA384, SHA512, String, UInt8

### Community 13 - "Community 13"
Cohesion: 0.09
Nodes (16): BSWEnvironment, production, staging, Bool, Date, Observable, ObservationBox, ObservationTests (+8 more)

### Community 14 - "Community 14"
Cohesion: 0.48
Nodes (6): backup_package_swift(), build_framework(), modify_package_swift(), restore_package_swift(), SKIP_ZERO, build.sh script

### Community 15 - "Community 15"
Cohesion: 0.25
Nodes (7): APIClient, Async And Observation, Constants, Module Map, Parsing, Persistence, Platform Utilities

### Community 16 - "Community 16"
Cohesion: 0.33
Nodes (5): 001 - Shared SwiftPM Foundation Package, Consequences, Context, Decision, Status

### Community 17 - "Community 17"
Cohesion: 0.33
Nodes (5): 002 - Skip Android Supported Subset, Consequences, Context, Decision, Status

### Community 19 - "Community 19"
Cohesion: 0.33
Nodes (5): Collections, Concurrency And Utilities, Foundation Extensions, Platform And Runtime, Strings And Crypto

### Community 20 - "Community 20"
Cohesion: 0.33
Nodes (5): Location And Progress, LocationFetcher, Platform Boundary, ProgressObserver, Throttler

### Community 21 - "Community 21"
Cohesion: 0.33
Nodes (5): Consequences, Context, Decision, NNN - Title, Status

### Community 22 - "Community 22"
Cohesion: 0.40
Nodes (4): GitHub PR Conventions, Graphify, Project Context Docs, Repository Instructions

### Community 24 - "Community 24"
Cohesion: 0.40
Nodes (4): Android Via Skip, Apple Platforms, Compatibility Rule, Platform Support

### Community 25 - "Community 25"
Cohesion: 0.40
Nodes (4): Dependencies, Documentation Responsibilities, Package Shape, Project Overview

### Community 26 - "Community 26"
Cohesion: 0.50
Nodes (4): BSWFoundation Knowledge Base, Decisions, Quick Start, Systems

### Community 28 - "Community 28"
Cohesion: 0.33
Nodes (5): APIClient, Core Contracts, Operational Notes, Request Flow, Request Variants

### Community 29 - "Community 29"
Cohesion: 0.40
Nodes (4): Async Streams And Observation, AsyncStreamDispatcher, Observation Stream, Testing Notes

### Community 31 - "Community 31"
Cohesion: 0.50
Nodes (3): About, Android Support, Documentation

### Community 32 - "Community 32"
Cohesion: 0.25
Nodes (5): JSONParser, Parsing, Maintenance Triggers, Open Items, Technical Pending

## Knowledge Gaps
- **121 isolated node(s):** `PackageDescription`, `APIClient`, `malformedURL`, `malformedResponse`, `encodingRequestFailed` (+116 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Foundation` connect `Community 9` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 10`, `Community 11`, `Community 12`, `Community 13`?**
  _High betweenness centrality (0.221) - this node is a cross-community bridge._
- **Why does `Persistence And JWT` connect `Community 1` to `Community 3`?**
  _High betweenness centrality (0.165) - this node is a cross-community bridge._
- **Why does `AuthStorage` connect `Community 1` to `Community 2`, `Community 11`, `Community 13`?**
  _High betweenness centrality (0.085) - this node is a cross-community bridge._
- **What connects `PackageDescription`, `APIClient`, `malformedURL` to the rest of the system?**
  _121 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.10668563300142248 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.06196078431372549 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.10153846153846154 - nodes in this community are weakly interconnected._
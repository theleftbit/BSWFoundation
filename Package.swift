// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let skipIsEnabled = (ProcessInfo.processInfo.environment["SKIP_ENABLED"] != nil)

let applePlatforms = TargetDependencyCondition.when(
    platforms: [
        .iOS,
        .macOS,
        .macCatalyst,
        .tvOS,
        .watchOS,
        .visionOS
    ]
)

// Platforms where URLSession / FoundationNetworking exist. Excludes WASM (WASI), where
// HTTPTypesFoundation's URLSession bridge does not compile.
let foundationNetworkingPlatforms = TargetDependencyCondition.when(
    platforms: [
        .iOS,
        .macOS,
        .macCatalyst,
        .tvOS,
        .watchOS,
        .visionOS,
        .linux,
        .android,
        .windows
    ]
)

var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "3.12.3"),
    .package(url: "https://github.com/apple/swift-http-types.git", from: "1.6.0"),
    .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.56.1"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
]

if skipIsEnabled {
    packageDependencies.append(contentsOf: [
        .package(url: "https://source.skip.tools/skip-fuse.git", from: "1.0.2"),
        .package(url: "https://source.skip.tools/skip-keychain.git", from: "0.3.0"),
    ])
}

var targetDependencies: [Target.Dependency] = [
    .product(name: "Crypto", package: "swift-crypto"),
    .product(name: "KeychainAccess", package: "KeychainAccess", condition: applePlatforms),
    .product(name: "HTTPTypes", package: "swift-http-types"),
    .product(name: "HTTPTypesFoundation", package: "swift-http-types", condition: foundationNetworkingPlatforms),
    .product(name: "JavaScriptKit", package: "JavaScriptKit", condition: .when(platforms: [.wasi])),
    .product(name: "JavaScriptEventLoop", package: "JavaScriptKit", condition: .when(platforms: [.wasi])),
    .product(name: "JavaScriptFoundationCompat", package: "JavaScriptKit", condition: .when(platforms: [.wasi])),
    .product(name: "Logging", package: "swift-log", condition: .when(platforms: [.wasi])),
]

if skipIsEnabled {
    targetDependencies.append(contentsOf: [
        .product(name: "SkipKeychain", package: "skip-keychain"),
        .product(name: "SkipFuse", package: "skip-fuse"),
    ])
}

let package = Package(
    name: "BSWFoundation",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v15),
        .macCatalyst(.v17),
        .watchOS(.v11),
    ],
    products: [
        .library(
            name: "BSWFoundation",
            targets: ["BSWFoundation"]
        ),
    ],
    dependencies: packageDependencies,
    targets: [
        .target(
            name: "BSWFoundation",
            dependencies: targetDependencies
        ),
        .testTarget(
            name: "BSWFoundationTests",
            dependencies: [
                "BSWFoundation",
                // On wasm, linking this activates the JavaScriptKit event-loop executor for the
                // test bundle, so async tests (Task.sleep, etc.) run instead of hitting an
                // unsupported WASI async-io syscall.
                .product(name: "JavaScriptEventLoopTestSupport", package: "JavaScriptKit", condition: .when(platforms: [.wasi])),
            ]
        ),
    ],
    swiftLanguageModes: [.v6],
)

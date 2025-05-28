// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let zero = ProcessInfo.processInfo.environment["SKIP_ZERO"] != nil

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

var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "3.12.3"),
]

if !zero {
    packageDependencies.append(contentsOf: [
        .package(url: "https://source.skip.tools/skip-fuse.git", from: "1.0.2"),
        .package(url: "https://source.skip.tools/skip-keychain.git", from: "0.3.0"),
    ])
}

var targetDependencies: [Target.Dependency] = [
    .product(name: "Crypto", package: "swift-crypto"),
    .product(name: "KeychainAccess", package: "KeychainAccess", condition: applePlatforms),
]

if !zero {
    targetDependencies.append(contentsOf: [
        .product(name: "SkipKeychain", package: "skip-keychain"),
        .product(name: "SkipFuse", package: "skip-fuse"),
    ])
}

let package = Package(
    name: "BSWFoundation",
    platforms: [
        .iOS(.v16),
        .tvOS(.v16),
        .macOS(.v13),
        .macCatalyst(.v16),
        .watchOS(.v9),
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
            dependencies: ["BSWFoundation"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

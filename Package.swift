// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let applePlatforms = TargetDependencyCondition.when(platforms: [.iOS, .macOS, .macCatalyst, .tvOS, .watchOS, .visionOS])
let androidPlatform = TargetDependencyCondition.when(platforms: [.android])

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
    dependencies: [
        .package(url: "https://source.skip.tools/skip-fuse.git", from: "1.0.1"),
        .package(url: "https://source.skip.tools/skip-keychain.git", from: "0.2.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.12.2"),
    ],
    targets: [
        .target(
            name: "BSWFoundation",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "KeychainAccess", package: "KeychainAccess", condition: applePlatforms),
                .product(name: "SkipKeychain", package: "skip-keychain", condition: androidPlatform),
                .product(name: "SkipFuse", package: "skip-fuse", condition: androidPlatform),
            ]
        ),
        .testTarget(
            name: "BSWFoundationTests",
            dependencies: ["BSWFoundation"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

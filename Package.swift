// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let applePlatforms = TargetDependencyCondition.when(platforms: [.iOS, .macOS, .macCatalyst, .tvOS, .watchOS, .visionOS])
let androidPlatforms = TargetDependencyCondition.when(platforms: [.android])

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
        .package(url: "https://github.com/skiptools/swift-android-native.git", from: "1.1.0"),
        .package(url: "https://github.com/skiptools/skip-keychain.git", from: "0.1.3"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "BSWFoundation",
            dependencies: [
                .product(name: "KeychainAccess", package: "KeychainAccess", condition: applePlatforms),
                .product(name: "SkipKeychain", package: "skip-keychain", condition: androidPlatforms),
                .product(name: "AndroidLogging", package: "swift-android-native", condition: androidPlatforms),
            ]
        ),
        .testTarget(
            name: "BSWFoundationTests",
            dependencies: ["BSWFoundation"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

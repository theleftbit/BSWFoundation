// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let applePlatforms = TargetDependencyCondition.when(platforms: [.iOS, .macOS, .macCatalyst, .tvOS, .watchOS])
let androidPlatforms = TargetDependencyCondition.when(platforms: [.android])

let package = Package(
    name: "BSWFoundation",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "BSWFoundation",
            targets: ["BSWFoundation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/skiptools/swift-android-native.git", from: "1.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "BSWFoundation",
            dependencies: [
                .product(name: "KeychainAccess", package: "KeychainAccess", condition: applePlatforms),
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

// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BSWFoundation",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "BSWFoundation",
            targets: ["BSWFoundation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "BSWFoundation",
            dependencies: ["KeychainAccess"]
        ),
        .testTarget(
            name: "BSWFoundationTests",
            dependencies: ["BSWFoundation"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

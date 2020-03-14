// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BSWFoundation",
    platforms: [
        .iOS(.v11),
        .tvOS(.v11),
        .macOS(.v10_13),
        .watchOS(.v4),
    ],
    products: [
        .library(
            name: "BSWFoundation",
            targets: ["BSWFoundation"]
        ),
        .library(
            name: "BSWTestCase",
            targets: ["BSWTestCase"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/bignerdranch/Deferred.git", from: "4.1.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "3.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .exact("1.7.2")),
    ],
    targets: [
        .target(
            name: "BSWFoundation",
            dependencies: ["Deferred", "KeychainAccess"]
        ),
        .target(name: "BSWTestCase", dependencies: ["SnapshotTesting"]),
        .testTarget(
            name: "BSWFoundationTests",
            dependencies: ["BSWFoundation", "BSWTestCase"]
        ),
    ]
)

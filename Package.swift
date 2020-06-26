// swift-tools-version:5.2
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
            type: .dynamic,
            targets: ["BSWFoundation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/theleftbit/Deferred.git", from: "4.2.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),
    ],
    targets: [
        .target(
            name: "BSWFoundation",
            dependencies: ["Deferred", "KeychainAccess"]
        ),
        .testTarget(
            name: "BSWFoundationTests",
            dependencies: ["BSWFoundation"]
        ),
    ]
)

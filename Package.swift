// swift-tools-version:5.9
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
            dependencies: ["KeychainAccess"],
            swiftSettings: [
                SwiftSetting.unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"]),
            ]
        ),
        .testTarget(
            name: "BSWFoundationTests",
            dependencies: ["BSWFoundation"]
        ),
    ]
)

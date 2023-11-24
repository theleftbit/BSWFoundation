// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let skipstone = Target.PluginUsage.plugin(name: "skipstone", package: "skip")

let package = Package(
    name: "BSWFoundation",
    platforms: [
        .iOS(.v16),
        .tvOS(.v15),
        .macOS(.v13),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "BSWFoundation",
            type: .dynamic,
            targets: ["BSWFoundation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://source.skip.tools/skip.git", from: "0.7.16"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "0.0.0"),
    ],
    targets: [
        .target(
            name: "BSWFoundation",
            dependencies: [
                .product(name: "SkipFoundation", package: "skip-foundation"),
                "KeychainAccess"
            ],
            resources: [.process("Resources")],
            swiftSettings: [
               // SwiftSetting.unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"]),
            ],
            plugins: [skipstone]
        ),
        .testTarget(
            name: "BSWFoundationTests",
            dependencies: [
                .product(name: "SkipTest", package: "skip"),
                "BSWFoundation"
            ],
            resources: [.process("Resources")],
            plugins: [skipstone]
        ),
    ]
)

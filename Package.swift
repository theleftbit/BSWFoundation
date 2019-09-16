// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BSWFoundation",
    products: [
        .library(
            name: "BSWFoundation",
            type: .dynamic,
            targets: ["BSWFoundation"]),
    ],
    dependencies: [
        .package(url: "https://github.com/theleftbit/Deferred.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "BSWFoundation",
            dependencies: ["Deferred"]),
        .testTarget(
            name: "BSWFoundationTests",
            dependencies: ["BSWFoundation"]),
    ]
)

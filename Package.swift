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
        .package(url: "https://github.com/bignerdranch/Deferred.git", from: "4.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "3.2.0"),
    ],
    targets: [
        .target(
            name: "BSWFoundation",
            dependencies: ["Deferred", "KeychainAccess"]),
        .testTarget(
            name: "BSWFoundationTests",
            dependencies: ["BSWFoundation"]),
    ]
)

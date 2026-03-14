// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let applePlatforms = TargetDependencyCondition.when(
    platforms: [
        .iOS,
        .macOS,
        .macCatalyst,
        .tvOS,
        .watchOS,
        .visionOS
    ]
)

var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    .package(url: "https://github.com/apple/swift-crypto.git", from: "3.12.3"),
]

var targetDependencies: [Target.Dependency] = [
    .product(name: "Crypto", package: "swift-crypto"),
    .product(name: "KeychainAccess", package: "KeychainAccess", condition: applePlatforms),
]

let package = Package(
    name: "BSWFoundation",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v15),
        .macCatalyst(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "BSWFoundation",
            targets: ["BSWFoundation"]
        ),
    ],
    dependencies: packageDependencies,
    targets: [
        .target(
            name: "BSWFoundation",
            dependencies: targetDependencies
        ),
        .testTarget(
            name: "BSWFoundationTests",
            dependencies: ["BSWFoundation"]
        ),
    ],
    swiftLanguageModes: [.v6],
)

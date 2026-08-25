// swift-tools-version: 6.2
import PackageDescription

// A small executable that exercises BSWFoundation's WebAssembly paths at runtime:
// a real `fetch` GET through FetchNetworkFetcher and a localStorage round-trip through
// UserDefaultsBacked. Build + run with:
//
//   swift package --swift-sdk swift-6.3.x-RELEASE_wasm js
//   node main.mjs
//
let package = Package(
    name: "WASMHarness",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(name: "BSWFoundation", path: ".."),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.56.1"),
    ],
    targets: [
        .executableTarget(
            name: "WASMHarness",
            dependencies: [
                .product(name: "BSWFoundation", package: "BSWFoundation"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

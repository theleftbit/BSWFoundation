
 [![](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fwww.emergetools.com%2Fapi%2Fv2%2Fpublic_new_build%3FexampleId%3Dbswfoundation.BSWFoundation%26platform%3Dios%26badgeOption%3Dversion_and_max_install_size%26buildType%3Drelease&query=$.badgeMetadata&label=BSWFoundation&logo=apple)](https://www.emergetools.com/app/example/ios/bswfoundation.BSWFoundation/release)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftheleftbit%2FBSWFoundation%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/theleftbit/BSWFoundation)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftheleftbit%2FBSWFoundation%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/theleftbit/BSWFoundation)

## About

 These are collection of types that are use throughout all TheLeftBit's iOS projects and that allow us to write better apps, faster.
 
 This project leverages heavily on Swift's [core features](https://swift.org/about/), so you have to be very profficient with these in order to understand why this types are so important.
 
## Documentation

Please checkout [the documentation](https://swiftpackageindex.com/theleftbit/BSWFoundation/documentation/) generated with DocC and hosted generously by Swift Package Index

## Android Support

Android support is in an ongoing effort, and it's' built on top of the [Skip Native toolchain](https://skip.tools/docs/native/). All features of this package except for `AuthStorage` and `LocationFetcher` are available and ready to use. 

If you find any issue, please report it using GitHub.

## WebAssembly / Browser Support

BSWFoundation compiles for WebAssembly and runs in the browser via [SwiftWasm](https://swiftwasm.org) and [JavaScriptKit](https://github.com/swiftwasm/JavaScriptKit). Networking goes through the browser's `fetch` API (`FetchNetworkFetcher`, used automatically as the default fetcher on wasm) and key-value storage (`KeychainBacked`, `UserDefaultsBacked`) through `localStorage`. As on Android, `AuthStorage` and `LocationFetcher` are excluded.

> ⚠️ On WebAssembly, `KeychainBacked` is backed by `localStorage`, which is **not** secure storage — values are not encrypted at rest.

### Running the test harness

[`WASMHarness/`](WASMHarness) is a small executable that exercises the wasm paths at runtime — a real `fetch` GET decoded by `JSONParser`, plus a `localStorage` round-trip through `KeychainBacked`.

1. **Install the WebAssembly Swift SDK** (once). The version must match your Swift toolchain — check `swift --version` and see [swift.org's WebAssembly guide](https://www.swift.org/documentation/articles/wasm-getting-started.html) for the current URL/checksum:

   ```sh
   swift sdk install \
     https://download.swift.org/swift-6.3.3-release/wasm-sdk/swift-6.3.3-RELEASE/swift-6.3.3-RELEASE_wasm.artifactbundle.tar.gz \
     --checksum cabfa08b73bb8ac783927ecd15fa386e99d0c139c5f232445067bcf58379cae7
   ```

2. **Build** the harness bundle (use the SDK id printed by `swift sdk list`):

   ```sh
   swift package --package-path WASMHarness --swift-sdk swift-6.3.3-RELEASE_wasm --disable-sandbox js
   ```

3. **Run in Node** — Node provides `fetch`; `main.mjs` shims `localStorage`, which Node lacks:

   ```sh
   npm install --prefix WASMHarness   # installs @bjorn3/browser_wasi_shim
   node WASMHarness/main.mjs
   ```

   Expected output:

   ```
   ✅ fetch GET https://httpbingo.org/ip → origin = …
   ✅ KeychainBacked localStorage round-trip → 'hello-from-wasm'
   ```

4. **Run in a browser** — `fetch` and `localStorage` are both native there. Serve the folder over HTTP (wasm can't load from `file://`) and open `index.html`:

   ```sh
   npx serve WASMHarness   # then open the printed URL + /index.html and check the devtools console
   ```

### Production builds & binary size

A **debug** wasm build is very large (~76 MB) — never ship it. For deployment, build in
**release** *and* make sure [Binaryen](https://github.com/WebAssembly/binaryen)'s `wasm-opt` is on
`PATH` before building, so the PackageToJS plugin runs its size-optimization pass. What the browser
actually downloads is the compressed (`Content-Encoding: br`/`gzip`) file, which is far smaller.

Reference sizes for the `WASMHarness` bundle (which links all of BSWFoundation + Foundation):

| Build | raw | gzip | brotli (served) |
|---|---|---|---|
| debug | ~76 MB | — | — |
| release, no `wasm-opt` | ~71 MB | ~23 MB | — |
| **release + `wasm-opt`** | **~45 MB** | ~18 MB | **~12 MB** |

```sh
brew install binaryen   # or your platform's package providing `wasm-opt`
swift package --package-path WASMHarness --swift-sdk swift-6.3.3-RELEASE_wasm --disable-sandbox js -c release
```

Then serve the `.wasm` with brotli or gzip enabled (browsers stream-compile it). Most of the
remaining size is the Swift runtime + Foundation — an inherent baseline for Swift-with-Foundation
in the browser. To go further, a production build can also strip reflection metadata
(`-Xswiftc -disable-reflection-metadata`), at the cost of `Mirror`/runtime reflection.

The whole package also has a wasm compile gate in CI (plus the unit tests run on wasm in Node), and builds are verified on Apple, Android, and WebAssembly.

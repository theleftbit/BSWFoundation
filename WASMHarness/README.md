# BSWFoundation WebAssembly harness

A tiny executable that proves BSWFoundation's WebAssembly paths work at **runtime**
(not just at compile time) in a real JavaScript host:

- a real `fetch` GET through `FetchNetworkFetcher`, decoded by `JSONParser`, and
- a `localStorage` round-trip through `KeychainBacked` → `WASMKeyValueStore`.

## Build

```sh
swift package --package-path WASMHarness \
  --swift-sdk swift-6.3.x-RELEASE_wasm \
  --disable-sandbox js
```

This bundles to `WASMHarness/.build/plugins/PackageToJS/outputs/Package/`
(both a Node and a browser entrypoint are generated).

## Run in Node

Node has `fetch` built in but no `localStorage`, so `main.mjs` shims it in memory.

```sh
npm install --prefix WASMHarness   # installs @bjorn3/browser_wasi_shim (see package.json)
node WASMHarness/main.mjs
```

Expected output:

```
— BSWFoundation WebAssembly runtime harness —
✅ fetch GET https://httpbingo.org/ip → origin = …
✅ KeychainBacked localStorage round-trip → 'hello-from-wasm'
— harness complete —
```

## Run in a browser

In a browser both `fetch` and `localStorage` are native — no shims. Serve this
folder over HTTP (wasm can't load from `file://`) and open `index.html`:

```sh
npx serve WASMHarness   # or any static file server
# open the printed URL + /index.html and check the devtools console
```

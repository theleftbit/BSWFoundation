// Prelude for running BSWFoundation's test suite on WebAssembly under Node
// (`swift package --swift-sdk … js test --prelude .github/wasm-prelude.js`).
//
// Node provides `fetch` but not `localStorage` (a browser API), so we shim it in memory
// for the storage tests (KeychainBacked / UserDefaultsBacked → WASMKeyValueStore).
const store = new Map()
globalThis.localStorage = {
    getItem: (key) => (store.has(key) ? store.get(key) : null),
    setItem: (key, value) => { store.set(key, String(value)) },
    removeItem: (key) => { store.delete(key) },
}

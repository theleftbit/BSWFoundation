// Node.js runner for the BSWFoundation WebAssembly harness.
//
//   swift package --swift-sdk swift-6.3.x-RELEASE_wasm js
//   node main.mjs
//
// node provides `fetch`, but not `localStorage` (a browser API), so we shim it in memory.

import { instantiate } from "./.build/plugins/PackageToJS/outputs/Package/instantiate.js"
import { defaultNodeSetup } from "./.build/plugins/PackageToJS/outputs/Package/platforms/node.js"

// Minimal in-memory localStorage shim (node has no localStorage).
const _store = new Map()
globalThis.localStorage = {
    getItem: (key) => (_store.has(key) ? _store.get(key) : null),
    setItem: (key, value) => { _store.set(key, String(value)) },
    removeItem: (key) => { _store.delete(key) },
}

async function main() {
    let resolveDone
    const done = new Promise((resolve) => { resolveDone = resolve })
    globalThis.__harnessDone = () => resolveDone()

    const options = await defaultNodeSetup()
    await instantiate(options)   // runs WASMHarness.main(), which starts the async Task
    await done                   // wait until the Swift harness signals completion
}

main()

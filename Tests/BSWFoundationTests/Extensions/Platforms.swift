
/// Bundle.module is not available on Android
/// unit tests, so for now we are turning these off
var isAndroid: Bool {
    #if os(Android)
    return true
    #else
    return false
    #endif
}

/// On WebAssembly, storage is localStorage-backed and `UserDefaults.standard` semantics differ,
/// so some Apple-coupled tests are turned off there (their wasm paths are covered by `WASMHarness`).
var isWASI: Bool {
    #if os(WASI)
    return true
    #else
    return false
    #endif
}

//
//  localStorage-backed key-value storage for WebAssembly.
//

#if os(WASI)
import Foundation
import JavaScriptKit

/// A `window.localStorage`-backed key-value store, used to implement the storage property
/// wrappers on WebAssembly, where there is neither a Keychain nor `UserDefaults`.
///
/// - Warning: `localStorage` is plain-text, origin-scoped browser storage — it is **not** secure.
///   Values written through `KeychainBacked` are therefore not encrypted at rest on wasm.
public final class WASMKeyValueStore: @unchecked Sendable {

    public static let shared = WASMKeyValueStore()

    /// `nil` when `localStorage` is unavailable (e.g. a Worker context); the store then no-ops.
    private let localStorage: JSObject?

    private init() {
        localStorage = JSObject.global.localStorage.object
    }

    public func string(forKey key: String) -> String? {
        guard let localStorage else { return nil }
        return localStorage.getItem!(key).string
    }

    public func data(forKey key: String) -> Data? {
        string(forKey: key)?.data(using: .utf8)
    }

    /// Sets the string value, or removes the key when `value` is `nil`.
    public func set(_ value: String?, forKey key: String) {
        guard let localStorage else { return }
        if let value {
            _ = localStorage.setItem!(key, value)
        } else {
            _ = localStorage.removeItem!(key)
        }
    }

    /// Sets the data value (stored as its UTF-8 string), or removes the key when `value` is `nil`.
    public func set(_ value: Data?, forKey key: String) {
        set(value.flatMap { String(data: $0, encoding: .utf8) }, forKey: key)
    }

    public func removeObject(forKey key: String) {
        set(String?.none, forKey: key)
    }
}
#endif

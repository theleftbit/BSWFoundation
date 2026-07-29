//
//  Created by Pierluigi Cifani on 13/06/2019.
//

import Foundation

#if os(Android)
import SkipFuse
import SkipAndroidBridge
#elseif os(WASI)
import JavaScriptKit
#endif

/// Supported everywhere except Linux. On WebAssembly it is backed by `localStorage`
/// through an internal browser storage adapter.
#if !os(Linux)
/// Stores the given `T` type on User Defaults.
///
/// The value parameter can be only property list objects: `NSData`, `NSString`, `NSNumber`, `NSDate`, `NSArray`, or `NSDictionary`.
@propertyWrapper
public final class UserDefaultsBacked<T: Sendable>: Sendable {
    private let key: String
    private let defaultValue: T?
    #if os(WASI)
    private let store = WASMKeyValueStore.shared
    #else
    private nonisolated(unsafe) let store: UserDefaults
    #endif

    public init(key: String, defaultValue: T? = nil, appGroupID: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        #if canImport(Darwin)
        self.store = {
            if let appGroupID = appGroupID {
                return UserDefaults(suiteName: appGroupID)!
            } else {
                return UserDefaults.standard
            }
        }()
        #elseif os(Android)
        self.store = SkipAndroidBridge.AndroidUserDefaults.standard
        #endif
    }

    public var wrappedValue: T? {
        get {
            #if canImport(Darwin)
            guard let value = self.store.object(forKey: key) as? T else {
                return defaultValue
            }
            return value
            #elseif os(WASI)
            if T.self == Bool.self {
                return (store.string(forKey: key).map { $0 == "true" } as? T) ?? defaultValue
            } else if T.self == String.self {
                return (store.string(forKey: key) as? T) ?? defaultValue
            } else {
                fatalError("Type not yet supported on WebAssembly")
            }
            #else
            if T.self == Bool.self {
                return self.store.bool(forKey: key) as? T
            } else if T.self == String.self {
                return (self.store.string(forKey: key) as? T) ?? defaultValue
            } else {
                fatalError("Type not yet supported on non-Darwin platforms")
            }
            #endif
        } set {
            #if os(WASI)
            if let newValue {
                if let bool = newValue as? Bool {
                    store.set(bool ? "true" : "false", forKey: key)
                } else if let string = newValue as? String {
                    store.set(string, forKey: key)
                } else {
                    fatalError("Type not yet supported on WebAssembly")
                }
            } else {
                store.removeObject(forKey: key)
            }
            #else
            if newValue != nil {
                self.store.set(newValue, forKey: key)
            } else {
                self.store.removeObject(forKey: key)
            }
            _ = self.store.synchronize()
            #endif
        }
    }
}

public extension UserDefaultsBacked {
    func reset() {
        self.store.removeObject(forKey: key)
    }
}


/// Stores the given `T` type on User Defaults (as long as it's `Codable`)
@propertyWrapper
public final class CodableUserDefaultsBacked<T: Codable & Sendable>: Sendable {
    private let key: String
    private let defaultValue: T?
    #if os(WASI)
    private let store = WASMKeyValueStore.shared
    #else
    private nonisolated(unsafe) let store: UserDefaults
    #endif

    public init(key: String, defaultValue: T? = nil, appGroupID: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        #if canImport(Darwin)
        self.store = {
            if let appGroupID = appGroupID {
                return UserDefaults(suiteName: appGroupID)!
            } else {
                return UserDefaults.standard
            }
        }()
        #elseif os(Android)
        self.store = SkipAndroidBridge.AndroidUserDefaults.standard
        #endif
    }

    public var wrappedValue: T? {
        get {
            guard let data = store.data(forKey: key) else {
                return defaultValue
            }
            return try? JSONDecoder().decode(T.self, from: data)
        } set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                store.set(data, forKey: key)
            } else {
                #if os(WASI)
                store.set(Data?.none, forKey: key)
                #else
                store.set(nil, forKey: key)
                #endif
            }
            #if !os(WASI)
            _ = store.synchronize()
            #endif
        }
    }
}

public extension CodableUserDefaultsBacked {
    func reset() {
        self.store.removeObject(forKey: key)
    }
}

#if os(WASI)
private final class WASMKeyValueStore: @unchecked Sendable {

    static let shared = WASMKeyValueStore()

    /// `nil` when `localStorage` is unavailable (e.g. a Worker context); the store then no-ops.
    private let localStorage: JSObject?

    private init() {
        localStorage = JSObject.global.localStorage.object
    }

    func string(forKey key: String) -> String? {
        guard let localStorage else { return nil }
        return localStorage.getItem!(key).string
    }

    func data(forKey key: String) -> Data? {
        string(forKey: key)?.data(using: .utf8)
    }

    func set(_ value: String?, forKey key: String) {
        guard let localStorage else { return }
        if let value {
            _ = localStorage.setItem!(key, value)
        } else {
            _ = localStorage.removeItem!(key)
        }
    }

    func set(_ value: Data?, forKey key: String) {
        set(value.flatMap { String(data: $0, encoding: .utf8) }, forKey: key)
    }

    func removeObject(forKey key: String) {
        set(String?.none, forKey: key)
    }
}
#endif
#endif

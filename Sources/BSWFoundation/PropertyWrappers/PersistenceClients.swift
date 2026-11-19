import Dependencies
import Foundation

#if os(Android)
import SkipAndroidBridge
import SkipFuse
import SkipKeychain
#elseif os(anyAppleOS)
@preconcurrency import KeychainAccess
#endif

#if !os(Linux)
/// Creates user defaults stores for the persistence wrappers.
///
/// Override `DependencyValues.bswUserDefaults` with a fresh ``inMemory()`` client
/// in each test. Stores created by one client share values within the same suite.
public struct UserDefaultsClient: Sendable {
    /// Resolves standard defaults (`nil`) or an app group suite.
    public var store: @Sendable (_ appGroupID: String?) -> Store

    public init(store: @escaping @Sendable (_ appGroupID: String?) -> Store) {
        self.store = store
    }

    /// The synchronous operations used by a user defaults wrapper.
    public struct Store: Sendable {
        /// Reads a value of the requested type. The type lets Android select its typed getter.
        public var read: @Sendable (_ key: String, _ type: Any.Type) -> Any?
        /// Reads a defaults flag using `UserDefaults.bool(forKey:)` coercion semantics.
        public var readBool: @Sendable (_ key: String) -> Bool
        public var set: @Sendable (_ value: Any?, _ key: String) -> Void
        public var remove: @Sendable (_ key: String) -> Void
        public var synchronize: @Sendable () -> Void

        public init(
            read: @escaping @Sendable (String, Any.Type) -> Any?,
            set: @escaping @Sendable (Any?, String) -> Void,
            remove: @escaping @Sendable (String) -> Void,
            readBool: (@Sendable (String) -> Bool)? = nil,
            synchronize: @escaping @Sendable () -> Void = {}
        ) {
            self.read = read
            self.readBool = readBool ?? { key in
                let value = read(key, Bool.self)
                if let value = value as? Bool { return value }
                if let value = value as? NSNumber { return value.boolValue }
                if let value = value as? NSString { return value.boolValue }
                return false
            }
            self.set = set
            self.remove = remove
            self.synchronize = synchronize
        }
    }

    /// Uses the platform's persistent defaults, retaining existing Android type support.
    public static let live = Self { appGroupID in
        #if os(anyAppleOS)
        let storage = UserDefaultsReference(
            appGroupID.map { UserDefaults(suiteName: $0)! } ?? .standard
        )
        return Store(
            read: { key, _ in storage.value.object(forKey: key) },
            set: { value, key in storage.value.set(value, forKey: key) },
            remove: { key in storage.value.removeObject(forKey: key) },
            readBool: { key in storage.value.bool(forKey: key) },
            synchronize: { _ = storage.value.synchronize() }
        )
        #else
        let storage = UserDefaultsReference(SkipAndroidBridge.AndroidUserDefaults.standard)
        return Store(
            read: { key, type in
                if type == Bool.self {
                    return storage.value.bool(forKey: key)
                } else if type == String.self {
                    return storage.value.string(forKey: key)
                } else if type == Data.self {
                    return storage.value.data(forKey: key)
                } else {
                    fatalError("Type not yet supported on non-Apple platforms")
                }
            },
            set: { value, key in storage.value.set(value, forKey: key) },
            remove: { key in storage.value.removeObject(forKey: key) },
            synchronize: { _ = storage.value.synchronize() }
        )
        #endif
    }

    /// Creates fresh, thread-safe storage with separate standard and app group namespaces.
    public static func inMemory() -> Self {
        let storage = InMemoryPersistence<String?, Any>()
        return Self { suite in
            Store(
                read: { key, _ in storage.read(key, namespace: suite) },
                set: { value, key in storage.set(value, key: key, namespace: suite) },
                remove: { key in storage.set(nil, key: key, namespace: suite) }
            )
        }
    }
}

/// Creates keychain stores for the persistence wrappers.
public struct KeychainClient: Sendable {
    /// Resolves a service and access group. A `nil` service uses the app bundle identifier.
    public var store: @Sendable (_ service: String?, _ accessGroup: String?) -> Store

    public init(store: @escaping @Sendable (_ service: String?, _ accessGroup: String?) -> Store) {
        self.store = store
    }

    /// The synchronous string operations used by a keychain wrapper.
    public struct Store: Sendable {
        public var read: @Sendable (_ key: String) -> String?
        public var set: @Sendable (_ value: String?, _ key: String) -> Void

        public init(
            read: @escaping @Sendable (String) -> String?,
            set: @escaping @Sendable (String?, String) -> Void
        ) {
            self.read = read
            self.set = set
        }
    }

    /// Uses KeychainAccess on Apple platforms and SkipKeychain on Android.
    public static let live = Self { service, accessGroup in
        #if os(anyAppleOS)
        let service = service ?? Bundle.main.bundleIdentifier!
        let keychain = accessGroup.map { Keychain(service: service, accessGroup: $0) }
            ?? Keychain(service: service)
        return Store(
            read: { key in keychain[key] },
            set: { value, key in keychain[key] = value }
        )
        #else
        return Store(
            read: { key in try? Keychain.shared.string(forKey: key) },
            set: { value, key in
                if let value {
                    try? Keychain.shared.set(value, forKey: key)
                } else {
                    try? Keychain.shared.removeValue(forKey: key)
                }
            }
        )
        #endif
    }

    /// Creates fresh, thread-safe storage separated by service and access group.
    public static func inMemory() -> Self {
        struct Namespace: Hashable {
            let service: String?
            let accessGroup: String?
        }
        let storage = InMemoryPersistence<Namespace, String>()
        return Self { service, accessGroup in
            let namespace = Namespace(service: service, accessGroup: accessGroup)
            return Store(
                read: { key in storage.read(key, namespace: namespace) },
                set: { value, key in storage.set(value, key: key, namespace: namespace) }
            )
        }
    }
}

public extension DependencyValues {
    /// Storage captured by user defaults wrappers when they are initialized.
    var bswUserDefaults: UserDefaultsClient {
        get { self[UserDefaultsClientKey.self] }
        set { self[UserDefaultsClientKey.self] = newValue }
    }

    /// Storage captured by keychain wrappers when they are initialized.
    var bswKeychain: KeychainClient {
        get { self[KeychainClientKey.self] }
        set { self[KeychainClientKey.self] = newValue }
    }
}

private enum UserDefaultsClientKey: DependencyKey {
    static let liveValue = UserDefaultsClient.live
    static var previewValue: UserDefaultsClient { .inMemory() }
    // The default testValue reports a missing override and falls back to previewValue,
    // ensuring an unconfigured test never accesses persistent storage.
}

private enum KeychainClientKey: DependencyKey {
    static let liveValue = KeychainClient.live
    static var previewValue: KeychainClient { .inMemory() }
}

// UserDefaults supports concurrent access but does not declare Sendable.
private final class UserDefaultsReference: @unchecked Sendable {
    let value: UserDefaults

    init(_ value: UserDefaults) {
        self.value = value
    }
}

// Every access to the dictionary is protected by the lock. Values follow the same
// property-list/value semantics expected by the wrappers' live implementations.
private final class InMemoryPersistence<Namespace: Hashable, Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Namespace: [String: Value]] = [:]

    func read(_ key: String, namespace: Namespace) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return values[namespace]?[key]
    }

    func set(_ value: Value?, key: String, namespace: Namespace) {
        lock.lock()
        defer { lock.unlock() }
        values[namespace, default: [:]][key] = value
    }
}
#endif

//
//  Created by Pierluigi Cifani on 13/06/2019.
//

import Foundation
import Dependencies

#if !os(Linux)
/// Stores the given `T` type on User Defaults.
///
/// The value parameter can be only property list objects: `NSData`, `NSString`, `NSNumber`, `NSDate`, `NSArray`, or `NSDictionary`.
/// Captures `DependencyValues.bswUserDefaults` during initialization.
@propertyWrapper
public final class UserDefaultsBacked<T: Sendable>: Sendable {
    private let key: String
    private let defaultValue: T?
    private let store: UserDefaultsClient.Store
    
    public init(key: String, defaultValue: T? = nil, appGroupID: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        @Dependency(\.bswUserDefaults) var client
        self.store = client.store(appGroupID)
    }
    
    public var wrappedValue: T? {
        get {
            #if os(Android)
            guard T.self == Bool.self || T.self == String.self else {
                fatalError("Type not yet supported on non-Apple platforms")
            }
            #endif
            return (store.read(key, T.self) as? T) ?? defaultValue
        } set {
            if newValue != nil {
                self.store.set(newValue, key)
            } else {
                self.store.remove(key)
            }
            store.synchronize()
        }
    }
}

public extension UserDefaultsBacked {
    func reset() {
        self.store.remove(key)
    }
}


/// Stores the given `T` type on User Defaults (as long as it's `Codable`)
/// Captures `DependencyValues.bswUserDefaults` during initialization.
@propertyWrapper
public final class CodableUserDefaultsBacked<T: Codable & Sendable>: Sendable {
    private let key: String
    private let defaultValue: T?
    private let store: UserDefaultsClient.Store

    public init(key: String, defaultValue: T? = nil, appGroupID: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        @Dependency(\.bswUserDefaults) var client
        self.store = client.store(appGroupID)
    }
    
    public var wrappedValue: T? {
        get {
            guard let data = store.read(key, Data.self) as? Data else {
                return defaultValue
            }
            return try? JSONDecoder().decode(T.self, from: data)
        } set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                store.set(data, key)
            } else {
                store.set(nil, key)
            }
            store.synchronize()
        }
    }
}

public extension CodableUserDefaultsBacked {
    func reset() {
        self.store.remove(key)
    }
}
#endif

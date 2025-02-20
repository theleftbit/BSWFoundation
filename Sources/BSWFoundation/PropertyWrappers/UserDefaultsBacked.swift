//
//  Created by Pierluigi Cifani on 13/06/2019.
//

import Foundation
import SkipFuse

/// Stores the given `T` type on User Defaults.
///
/// The value parameter can be only property list objects: `NSData`, `NSString`, `NSNumber`, `NSDate`, `NSArray`, or `NSDictionary`.
@propertyWrapper
public final class UserDefaultsBacked<T: Sendable>: Sendable {
    private let key: String
    private let defaultValue: T?
    private nonisolated(unsafe) let store: UserDefaults
    
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
        #else
        self.store = UserDefaults.bridged
        #endif
    }
    
    public var wrappedValue: T? {
        get {
            #if canImport(Darwin)
            guard let value = self.store.object(forKey: key) as? T else {
                return defaultValue
            }
            return value
            #else
            if T.self == Bool.self {
                return self.store.bool(forKey: key) as? T
            } else if T.self == String.self, let value = self.store.string(forKey: key) {
                return value as? T
            } else {
                return defaultValue
            }
            #endif
        } set {
            if newValue != nil {
                self.store.set(newValue, forKey: key)
            } else {
                self.store.removeObject(forKey: key)
            }
            _ = self.store.synchronize()
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
    private nonisolated(unsafe) let store: UserDefaults

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
        #else
        self.store = UserDefaults.bridged
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
                store.set(nil, forKey: key)
            }
            _ = store.synchronize()
        }
    }
}

public extension CodableUserDefaultsBacked {
    func reset() {
        self.store.removeObject(forKey: key)
    }
}

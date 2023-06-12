//
//  Created by Pierluigi Cifani on 13/06/2019.
//

import Foundation

/// Stores the given `T` type on User Defaults.
///
/// The value parameter can be only property list objects: `NSData`, `NSString`, `NSNumber`, `NSDate`, `NSArray`, or `NSDictionary`.
@propertyWrapper
public class UserDefaultsBacked<T> {
    private let key: String
    private let defaultValue: T?
    private let store: UserDefaults
    
    public init(key: String, defaultValue: T? = nil, appGroupID: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = {
            if let appGroupID = appGroupID {
                return UserDefaults(suiteName: appGroupID)!
            } else {
                return UserDefaults.standard
            }
        }()
    }
    
    public var wrappedValue: T? {
        get {
            guard let value = self.store.object(forKey: key) as? T else {
                return defaultValue
            }
            return value
        } set {
            if newValue != nil {
                self.store.set(newValue, forKey: key)
            } else {
                self.store.removeObject(forKey: key)
            }
            self.store.synchronize()
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
public class CodableUserDefaultsBacked<T: Codable> {
    private let key: String
    private let defaultValue: T?
    private let store: UserDefaults

    public init(key: String, defaultValue: T? = nil, appGroupID: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = {
            if let appGroupID = appGroupID {
                return UserDefaults(suiteName: appGroupID)!
            } else {
                return UserDefaults.standard
            }
        }()
    }
    
    public var wrappedValue: T? {
        get {
            guard let data = self.store.data(forKey: key) else {
                return defaultValue
            }
            return try? JSONDecoder().decode(T.self, from: data)
        } set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }
            self.store.set(data, forKey: key)
            self.store.synchronize()
        }
    }
}

public extension CodableUserDefaultsBacked {
    func reset() {
        self.store.removeObject(forKey: key)
    }
}

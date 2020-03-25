//
//  Created by Pierluigi Cifani on 13/06/2019.
//

import Foundation

@propertyWrapper
public class UserDefaultsBacked<T> {
    private let key: String
    private let defaultValue: T?

    public init(key: String, defaultValue: T? = nil) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: T? {
        get {
            guard let value = UserDefaults.standard.object(forKey: key) as? T else {
                return defaultValue
            }
            return value
        } set {
            if newValue != nil {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
            UserDefaults.standard.synchronize()
        }
    }
}

public extension UserDefaultsBacked {
    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}


@propertyWrapper
public class CodableUserDefaultsBacked<T: Codable> {
    private let key: String
    private let defaultValue: T?

    public init(key: String, defaultValue: T? = nil) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue: T? {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else {
                return defaultValue
            }
            return try? JSONDecoder().decode(T.self, from: data)
        } set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}

public extension CodableUserDefaultsBacked {
    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

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
            UserDefaults.standard.set(newValue, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
}

public extension UserDefaultsBacked {
    func reset() {
        value = nil
    }
}

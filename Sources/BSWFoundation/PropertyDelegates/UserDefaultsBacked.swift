//
//  Created by Pierluigi Cifani on 13/06/2019.
//

import Foundation

@propertyDelegate
public class UserDefaultsBacked<T> {
    private let key: String
    
    public init(key: String) {
        self.key = key
    }
    
    public var value: T? {
        get {
            return UserDefaults.standard.object(forKey: key) as? T
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

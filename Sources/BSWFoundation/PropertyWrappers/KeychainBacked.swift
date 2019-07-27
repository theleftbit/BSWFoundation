//
//  Created by Pierluigi Cifani on 20/06/2019.
//

import Foundation
import KeychainAccess

@propertyWrapper
public class KeychainBacked {
    private let key: String
    private let keychain = Keychain(service: Bundle.main.bundleIdentifier!)

    public init(key: String) {
        self.key = key
    }
    
    public var wrappedValue: String? {
        get {
            return keychain[key]
        } set {
            keychain[key] = newValue
        }
    }
}

public extension KeychainBacked {
    func reset() {
        value = nil
    }
}

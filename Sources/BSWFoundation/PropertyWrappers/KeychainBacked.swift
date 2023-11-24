//
//  Created by Pierluigi Cifani on 20/06/2019.
//

#if os(Android)
#else

import Foundation
import KeychainAccess

/// Stores a String on the Keychain
@propertyWrapper
public class KeychainBacked {
    private let key: String
    private let keychain: Keychain

    public init(key: String, appGroupID: String? = nil) {
        self.key = key
        self.keychain = {
            if let appGroupID = appGroupID {
                return Keychain(service: Bundle.main.bundleIdentifier!, accessGroup: appGroupID)
            } else {
                return Keychain(service: Bundle.main.bundleIdentifier!)
            }
        }()
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
        wrappedValue = nil
    }
}
#endif

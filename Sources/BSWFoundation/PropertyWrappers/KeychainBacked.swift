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

/// Stores the given `T` type on the Keychain (as long as it's `Codable`)
@propertyWrapper
public class CodableKeychainBacked<T: Codable> {
    private let key: String
    private let keychain = Keychain(service: Bundle.main.bundleIdentifier!)

    public init(key: String) {
        self.key = key
    }
    
    public var wrappedValue: T? {
        get {
            return keychain[key]?.decoded()
        } set {
            keychain[key] = newValue.encodedAsString()
        }
    }
}

public extension CodableKeychainBacked {
    func reset() {
        wrappedValue = nil
    }
}

private extension String  {
    func decoded<T: Decodable>() -> T? {
        guard let data = self.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

private extension Encodable {
    func encodedAsString() -> String? {
        guard let data = try? JSONEncoder().encode(self), let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
}
#endif

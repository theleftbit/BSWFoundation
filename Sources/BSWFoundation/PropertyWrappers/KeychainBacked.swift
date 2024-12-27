//
//  Created by Pierluigi Cifani on 20/06/2019.
//
import Foundation

#if canImport(Darwin)
import KeychainAccess
#else
import SkipKeychain
#endif

/// Stores a String on the Keychain
@propertyWrapper
public class KeychainBacked {
    private let key: String
    private let keychain: Keychain

    public init(key: String, appGroupID: String? = nil) {
        self.key = key
#if canImport(Darwin)
        self.keychain = {
            if let appGroupID = appGroupID {
                return Keychain(service: Bundle.main.bundleIdentifier!, accessGroup: appGroupID)
            } else {
                return Keychain(service: Bundle.main.bundleIdentifier!)
            }
        }()
#else
        self.keychain = Keychain.shared
#endif
    }
    
#if canImport(Darwin)
    public var wrappedValue: String? {
        get {
            return keychain[key]
        } set {
            keychain[key] = newValue
        }
    }
#else
    public var wrappedValue: String? {
        get {
            return try? keychain.string(forKey: key)
        } set {
            if let newValue {
                try? keychain.set(newValue, forKey: key)
            } else {
                try? keychain.removeValue(forKey: key)
            }
        }
    }
#endif
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
    private let keychain: Keychain

    public init(key: String) {
        self.key = key
#if canImport(Darwin)
        self.keychain = Keychain(service: Bundle.main.bundleIdentifier!)
#else
        self.keychain = Keychain.shared
#endif
    }
    
#if canImport(Darwin)
    public var wrappedValue: T? {
        get {
            return keychain[key]?.decoded()
        } set {
            keychain[key] = newValue.encodedAsString()
        }
    }
#else
    public var wrappedValue: T? {
        get {
            return try? keychain.string(forKey: key)?.decoded()
        } set {
            if let newValue, let stringValue = newValue.encodedAsString() {
                try? keychain.set(stringValue, forKey: key)
            } else {
                try? keychain.removeValue(forKey: key)
            }
        }
    }
#endif
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

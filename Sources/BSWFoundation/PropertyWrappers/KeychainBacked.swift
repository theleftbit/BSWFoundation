//
//  Created by Pierluigi Cifani on 20/06/2019.
//
import Foundation
import Dependencies

/// This is supported anywhere but Linux
#if !os(Linux)

/// Stores a String on the Keychain
/// Captures `DependencyValues.bswKeychain` during initialization.
@propertyWrapper
public class KeychainBacked {
    private let key: String
    private let keychain: KeychainClient.Store

    public init(key: String, appGroupID: String? = nil) {
        self.key = key
        @Dependency(\.bswKeychain) var client
        self.keychain = client.store(nil, appGroupID)
    }
    
    public var wrappedValue: String? {
        get {
            keychain.read(key)
        } set {
            keychain.set(newValue, key)
        }
    }
}

public extension KeychainBacked {
    func reset() {
        wrappedValue = nil
    }
}

/// Stores the given `T` type on the Keychain (as long as it's `Codable`)
/// Captures `DependencyValues.bswKeychain` during initialization.
@propertyWrapper
public class CodableKeychainBacked<T: Codable> {
    private let key: String
    private let keychain: KeychainClient.Store

    public init(key: String) {
        self.key = key
        @Dependency(\.bswKeychain) var client
        self.keychain = client.store(nil, nil)
    }
    
    public var wrappedValue: T? {
        get {
            keychain.read(key)?.decoded()
        } set {
            #if os(anyAppleOS)
            keychain.set(newValue.encodedAsString(), key)
            #else
            keychain.set(newValue?.encodedAsString(), key)
            #endif
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

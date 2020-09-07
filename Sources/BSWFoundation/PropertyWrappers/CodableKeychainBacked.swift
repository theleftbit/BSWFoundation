//
//  Created by Michele Restuccia on 07/09/2020.
//

import Foundation
import KeychainAccess

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

//
//  Created by Pierluigi Cifani on 13/06/2019.
//

import Foundation
/// Stores the given `T` type on User Defaults.
///
/// The value parameter can be only property list objects: `NSData`, `NSString`, `NSNumber`, `NSDate`, `NSArray`, or `NSDictionary`.
@propertyWrapper
public final class UserDefaultsBacked<T: Sendable>: Sendable {
    private let key: String
    private let defaultValue: T?
    private nonisolated(unsafe) let store: PreferencesStore
    
    public init(key: String, defaultValue: T? = nil, appGroupID: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
#if canImport(Darwin)
        self.store = {
            if let appGroupID = appGroupID {
                return UserDefaults(suiteName: appGroupID)!
            } else {
                return UserDefaults.standard
            }
        }()
#else
        self.store = PlistManager(plistName: "UserDefaults")
#endif
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
            _ = self.store.synchronize()
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
public final class CodableUserDefaultsBacked<T: Codable & Sendable>: Sendable {
    private let key: String
    private let defaultValue: T?
    private nonisolated(unsafe) let store: PreferencesStore

    public init(key: String, defaultValue: T? = nil, appGroupID: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
#if canImport(Darwin)
        self.store = {
            if let appGroupID = appGroupID {
                return UserDefaults(suiteName: appGroupID)!
            } else {
                return UserDefaults.standard
            }
        }()
#else
        self.store = PlistManager(plistName: "UserDefaults")
#endif
    }
    
    public var wrappedValue: T? {
        get {
            guard let data = store.data(forKey: key) else {
                return defaultValue
            }
            return try? JSONDecoder().decode(T.self, from: data)
        } set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                return
            }
            store.writeData(data, forKey: key)
            _ = store.synchronize()
        }
    }
}

public extension CodableUserDefaultsBacked {
    func reset() {
        self.store.removeObject(forKey: key)
    }
}

// MARK: Private

private protocol PreferencesStore {
    func set(_ value: Any?, forKey defaultName: String)
    func object(forKey defaultName: String) -> Any?
    func removeObject(forKey defaultName: String)
    
    func writeData(_ data: Data, forKey key: String)
    func data(forKey key: String) -> Data?
    func synchronize() -> Bool
}

extension UserDefaults: PreferencesStore {
    func writeData(_ data: Data, forKey key: String) {
        self.set(data, forKey: key)
    }
}

extension PlistManager: PreferencesStore {}

private class PlistManager {
    private let fileName: String
    private let fileURL: URL
    
    // Initializer
    init(plistName: String) {
        self.fileName = plistName.hasSuffix(".plist") ? plistName : "\(plistName).plist"
        
        // Determine the file path in the Documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Create the plist file if it doesn't exist
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let emptyDictionary: [String: Any] = [:]
            do {
                let data = try PropertyListSerialization.data(fromPropertyList: emptyDictionary, format: .xml, options: 0)
                try data.write(to: fileURL)
                print("Plist created at: \(fileURL.path)")
            } catch {
                print("Error creating plist: \(error)")
            }
        }
    }
    
    // Read value for a given key
    func object(forKey key: String) -> Any? {
        guard let data = try? Data(contentsOf: fileURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        return plist[key]
    }
    
    // Write value for a given key
    func set(_ value: Any?, forKey key: String) {
        guard let data = try? Data(contentsOf: fileURL),
              var plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            print("Failed to load or parse plist")
            return
        }
        
        plist[key] = value
        
        do {
            let updatedData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try updatedData.write(to: fileURL)
            print("Value for key '\(key)' written successfully.")
        } catch {
            print("Error writing to plist: \(error)")
        }
    }
    
    // Delete value for a given key
    func removeObject(forKey key: String) {
        guard let data = try? Data(contentsOf: fileURL),
              var plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            print("Failed to load or parse plist")
            return
        }
        
        plist.removeValue(forKey: key)
        
        do {
            let updatedData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try updatedData.write(to: fileURL)
            print("Key '\(key)' deleted successfully.")
        } catch {
            print("Error deleting value from plist: \(error)")
        }
    }
    
    func synchronize() -> Bool { true }
    
    func writeData(_ data: Data, forKey key: String) {
        let base64String = data.base64EncodedString()
        set(base64String, forKey: key)
    }

    func data(forKey key: String) -> Data? {
        guard let base64String = object(forKey: key) as? String,
              let decodedData = Data(base64Encoded: base64String) else {
            return nil
        }
        return decodedData
    }
}

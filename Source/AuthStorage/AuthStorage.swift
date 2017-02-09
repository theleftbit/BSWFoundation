//
//  Created by Pierluigi Cifani on 09/02/2017.
//  Copyright (c) 2017 Blurred Software SL. All rights reserved.
//

import Foundation
import KeychainAccess
import JWTDecode

public class AuthStorage {

    public static let defaultStorage = AuthStorage()
    fileprivate let keychain = Keychain(service: Bundle.main.bundleIdentifier!)
    fileprivate var jwt: JWT? {
        get {
            guard let jwtString = keychain[Keys.JWT] else { return nil}
            return try? decode(jwt: jwtString)
        }
    }

    fileprivate let userDefaults = UserDefaults.standard

    init() {
        guard !userDefaults.bool(forKey: Keys.HasAppBeenExecuted) else {
            return
        }

        // Clear the keychain on app's first launch, so the user
        // has to log-in again after an app delete
        clearKeychain()
        userDefaults.set(true, forKey: Keys.HasAppBeenExecuted)
        userDefaults.synchronize()
    }

    public func token() -> String? {
        let token = keychain[Keys.JWT]
        return token
    }

    public func setToken(_ authToken: String) throws {
        _ = try decode(jwt: authToken)
        keychain[Keys.JWT] = authToken
    }

    public var tokenIsExpired: Bool {
        guard let jwt = self.jwt else { return false }
        return jwt.expired
    }

    public func userID() -> String? {
        return keychain[Keys.UserID]
    }

    public func setUserID(_ userID: String) {
        keychain[Keys.UserID] = userID
    }

    public func clearKeychain() {
        keychain[Keys.JWT] = nil
        keychain[Keys.UserID] = nil
    }
}

private struct Keys {
    static let JWT = "JWT"
    static let UserID = "UserID"
    static let HasAppBeenExecuted = "HasAppBeenExecuted"
}

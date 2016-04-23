//
//  Created by Pierluigi Cifani on 23/04/16.
//  Copyright (c) 2016 Blurred Software SL. All rights reserved.
//

import Foundation

public typealias AuthToken = String

public class AuthStorage {

    private static let Key = "AuthToken"
    
    public static let defaultStorage = AuthStorage()
    
    public func authToken() -> AuthToken? {
        return NSUserDefaults.standardUserDefaults().objectForKey(AuthStorage.Key) as? AuthToken
    }
    
    public func setAuthToken(authToken: AuthToken) {
        NSUserDefaults.standardUserDefaults().setObject(authToken, forKey: AuthStorage.Key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
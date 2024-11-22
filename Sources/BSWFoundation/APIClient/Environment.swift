//
//  Created by Pierluigi Cifani on 29/04/16.
//  Copyright © 2018 TheLeftBit SL. All rights reserved.
//

#if os(Android)
import FoundationEssentials
#endif
import Foundation

/// Describes an environment to attack using a `APIClient`
public protocol Environment: Sendable {
    
    /// What URL to send the requests to.
    var baseURL: URL { get }
    
    /// If HTTPS should be enforced (including Certificate validations)
    var shouldAllowInsecureConnections: Bool { get }
}

public extension Environment {
    func routeURL(_ pathURL: String) -> String {
        return baseURL.absoluteString + pathURL
    }

    var shouldAllowInsecureConnections: Bool {
        return false
    }
}

//
//  Created by Pierluigi Cifani on 29/04/16.
//  Copyright © 2018 TheLeftBit SL. All rights reserved.
//

import Foundation

public struct Request<ResponseType>{
    let endpoint: Endpoint
}

public protocol Environment {
    var baseURL: URL { get }
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

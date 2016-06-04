//
//  Created by Pierluigi Cifani on 29/04/16.
//  Copyright © 2016 Blurred Software SL. All rights reserved.
//

import Foundation

public protocol Environment {
    var basePath: String { get }
}

public extension Environment {
    func routeURL(pathURL: String) -> String {
        return basePath + pathURL
    }
}
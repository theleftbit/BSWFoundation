//
//  Created by Pierluigi Cifani on 28/04/16.
//  Copyright © 2016 Blurred Software SL. All rights reserved.
//

import Foundation

public typealias UUID = String

public protocol Identifiable {
    var uuid: UUID { get }
}

extension Equatable where Self : Identifiable {
    
}

public func ==(lhs: Identifiable, rhs: Identifiable) -> Bool {
    return lhs.uuid == rhs.uuid
}

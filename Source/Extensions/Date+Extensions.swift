//
//  Created by Pierluigi Cifani on 11/30/15.
//

import Foundation

extension Date {

    public init(timestamp ts: Double, includesMiliseconds: Bool = false) {
        self.init(timeIntervalSince1970: ts * (includesMiliseconds ? 1/1000 : 1))
    }
    
    public func formattedStringTimestamp(_ includeMiliseconds: Bool = true) -> String {
        return "\(timestamp(includeMiliseconds:includeMiliseconds))"
    }

    public func timestamp(includeMiliseconds: Bool = true) -> UInt64 {
        return UInt64(floor(self.timeIntervalSince1970 * (includeMiliseconds ? 1000 : 1)))
    }
}

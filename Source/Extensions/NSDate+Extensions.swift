//
//  Created by Pierluigi Cifani on 11/30/15.
//

import Foundation

extension NSDate {

    public convenience init(timestamp ts: Double, includesMiliseconds: Bool = false) {
        self.init(timeIntervalSince1970: ts * (includesMiliseconds ? 1/1000 : 1))
    }
    
    func formattedStringTimestamp(includeMiliseconds: Bool = true) -> String {
        return "\(timestamp(includeMiliseconds:includeMiliseconds))"
    }

    func timestamp(includeMiliseconds includeMiliseconds: Bool = true) -> UInt64 {
        return UInt64(floor(self.timeIntervalSince1970 * (includeMiliseconds ? 1000 : 1)))
    }
}
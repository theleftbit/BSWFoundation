//
//  Created by Pierluigi Cifani on 09/12/15.
//  Copyright © 2015 Wallapop SL. All rights reserved.
//

import Foundation

extension String {
    public var length: Int {
        return characters.count
    }
    public var capitalizeFirst: String {
        if isEmpty { return "" }
        var result = self
        result.replaceRange(startIndex...startIndex, with: String(self[startIndex]).uppercaseString)
        return result
    }
    
    public func trimmedStringAndWithoutNewlineCharacters() -> String {
        return self.stringByReplacingOccurrencesOfString("\n", withString: " ").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
}

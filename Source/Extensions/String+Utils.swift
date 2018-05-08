//
//  Created by Pierluigi Cifani on 09/12/15.
//  Copyright © 2018 TheLeftBit SL SL. All rights reserved.
//

import Foundation

extension String {
    
    public var length: Int {
        return count
    }
    
    public var capitalizeFirst: String {
        if isEmpty { return "" }
        var result = self
        result.replaceSubrange(startIndex...startIndex, with: String(self[startIndex]).uppercased())
        return result
    }
    
    public func trimmedStringAndWithoutNewlineCharacters() -> String {
        return self.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

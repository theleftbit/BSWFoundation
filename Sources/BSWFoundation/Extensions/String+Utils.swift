//
//  Created by Pierluigi Cifani on 09/12/15.
//  Copyright © 2018 TheLeftBit SL SL. All rights reserved.
//

import Foundation

public extension String {
    
    var length: Int {
        return count
    }
    
    var capitalizeFirst: String {
        if isEmpty { return "" }
        var result = self
        result.replaceSubrange(startIndex...startIndex, with: String(self[startIndex]).uppercased())
        return result
    }
    
    func trimmedStringAndWithoutNewlineCharacters() -> String {
        return self.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

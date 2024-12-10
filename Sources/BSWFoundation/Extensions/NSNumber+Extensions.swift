//
//  Created by Pierluigi Cifani on 08/05/2018.
//

import Foundation

extension NSNumber {
    var isBool: Bool {
#if canImport(Darwin)
        return CFBooleanGetTypeID() == CFGetTypeID(self)
#else
        fatalError()
#endif
    }
}

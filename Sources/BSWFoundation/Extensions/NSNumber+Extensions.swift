//
//  Created by Pierluigi Cifani on 08/05/2018.
//

#if os(Android)
#else
import Foundation

extension NSNumber {
    var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

#endif

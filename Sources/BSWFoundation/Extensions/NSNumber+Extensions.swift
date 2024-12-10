//
//  Created by Pierluigi Cifani on 08/05/2018.
//

import Foundation
#if os(Android)
import FoundationEssentials
#endif

extension NSNumber {
    var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

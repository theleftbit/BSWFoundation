//
//  Created by Pierluigi Cifani on 08/05/2018.
//

#if os(Android)
import FoundationEssentials
#else
import Foundation
#endif


extension NSNumber {
    var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

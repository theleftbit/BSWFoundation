
#if os(iOS)

import UIKit

public extension UIApplication {
    var isRunningTests: Bool {
        #if DEBUG
        return NSClassFromString("XCTest") != nil
        #else
        return false
        #endif
    }
}

#endif

#if os(iOS)

import Testing
import BSWFoundation
import UIKit

actor UIApplicationTests {

    @MainActor
    @Test
    func itWorks() {
        #expect(UIApplication.shared.isRunningTests)
    }
}

#endif


#if os(iOS)

import Testing
import BSWFoundation

actor UIApplicationTests {

    @MainActor
    @Test
    func itWorks() {
        #expect(UIApplication.shared.isRunningTests)
    }
}

#endif


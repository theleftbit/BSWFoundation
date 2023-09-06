import Foundation

public extension ProcessInfo {
    /// Detects if the current process is running on a Mac.
    var isCatalystOriIOSAppOnMac: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return isiOSAppOnMac
        #endif
    }
}

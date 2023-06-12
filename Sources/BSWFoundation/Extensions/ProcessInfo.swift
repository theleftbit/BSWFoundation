import Foundation

public extension ProcessInfo {
    /// Detects if the current process is running on a Mac.
    var isCatalystOriIOSAppOnMac: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        if #available(iOS 14.0, macOS 11, *) {
            return isiOSAppOnMac
        } else {
            return false
        }
        #endif
    }
}

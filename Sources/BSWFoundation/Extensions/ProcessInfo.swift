#if os(Android)
#else
import Foundation

public extension ProcessInfo {
    /// Detects if the current process is running on a Mac.
    @inlinable
    var isCatalystOriIOSAppOnMac: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return isiOSAppOnMac
        #endif
    }
    
    @inlinable
    var isXcodePreview: Bool {
        #if DEBUG
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        false
        #endif
    }
}

#endif

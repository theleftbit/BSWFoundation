import Foundation

public extension ProcessInfo {
    /// Detects if the current process is running on a Mac.
    @inlinable
    var isCatalystOriIOSAppOnMac: Bool {
#if canImport(Darwin)
#if targetEnvironment(macCatalyst)
        return true
#elseif os(macOS)
        return true
#else
        return isiOSAppOnMac
#endif
#else
        return false
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

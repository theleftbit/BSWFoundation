//
//  Bundle+Extensions.swift
//  BSWFoundation
//
//  Created by Pierluigi Cifani on 07/05/2018.
//

#if os(Android)
import FoundationEssentials; import FoundationInternationalization
import Android
#endif
import Foundation

extension Bundle {
    var displayName: String {
        return object(forInfoDictionaryKey: "CFBundleName") as? String ?? "BSWFoundation"
    }
    
    var appVersion: String {
        return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }
    
    var appBuild: String {
        return object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    /// Returns the current OS Version. On Android, it'll return the API Level.
    public var operatingSystemVersion: String {
        #if os(Android)
        return "\(android_get_device_api_level())"
        #else
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #endif
    }
    
    public var osName: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        #if os(Android)
        let osName = "Android"
        #elseif os(watchOS)
        let osName = "watchOS"
        #else
        let osName = ProcessInfo.processInfo.isCatalystOriIOSAppOnMac ? "macOS" : "iOS"
        #endif
        return "\(osName) \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
}

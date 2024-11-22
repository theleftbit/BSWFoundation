//
//  Bundle+Extensions.swift
//  BSWFoundation
//
//  Created by Pierluigi Cifani on 07/05/2018.
//

#if os(Android)
import FoundationEssentials; import FoundationInternationalization
#endif
import Foundation

extension Bundle {
    var displayName: String {
#if os(Android)
        return "BSWFoundation-Android"
#else
        return object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? "BSWFoundation"
#endif
    }
    
    var appVersion: String {
        return (infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    }
    
    var appBuild: String {
        return (infoDictionary?["CFBundleVersion"] as? String) ?? ""
    }

    public var osName: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
#if os(Android)
        let osName = "Android"
#else
        let osName = ProcessInfo.processInfo.isCatalystOriIOSAppOnMac ? "macOS" : "iOS"
#endif
        return "\(osName) \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
}

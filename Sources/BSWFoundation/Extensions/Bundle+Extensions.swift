//
//  Bundle+Extensions.swift
//  BSWFoundation
//
//  Created by Pierluigi Cifani on 07/05/2018.
//

import Foundation

extension Bundle {
    var displayName: String {
        return object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? "BSWFoundation"
    }
    
    var appVersion: String {
        return object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "0"
    }
    
    var appBuild: String {
        return object(forInfoDictionaryKey: kCFBundleInfoDictionaryVersionKey as String) as? String ?? "1"
    }

    public var osName: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        #if os(iOS)
        return "iOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #else
        return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #endif
    }
}

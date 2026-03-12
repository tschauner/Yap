//
//  Bundle+Extension.swift
//  Yap
//
//  Created by Philipp Tschauner on 10.03.26.
//

import Foundation

extension Bundle {
    var internalVersionString: String? {
        let dictionary = infoDictionary
        let version = dictionary?["CFBundleShortVersionString"] as? String
        let build = dictionary?["CFBundleVersion"] as? String
        guard let version, let build, let appName else { return nil }
        return "\(appName), \(version).\(build)"
    }
    
    var versionString: String? {
        let dictionary = infoDictionary
        let version = dictionary?["CFBundleShortVersionString"] as? String
        guard let version, let appName else { return nil }
        return "\(appName), \(version)"
    }
    
    var appName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
                        object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}

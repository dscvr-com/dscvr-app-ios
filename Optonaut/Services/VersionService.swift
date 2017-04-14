//
//  VersionService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/3/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class VersionService {
    
    static let isNew: Bool = {
        let lastVersion = UserDefaults.standard.object(forKey: "last_release_version") as? String
        let newVersion = Bundle.main.releaseVersionNumber
        let lastBuild = UserDefaults.standard.object(forKey: "last_release_build") as? String
        let newBuild = Bundle.main.releaseBuildNumber
        return lastVersion != newVersion || lastBuild != newBuild
    }()
    
    static func updateToLatest() {
        if let version = Bundle.main.releaseVersionNumber, let build = Bundle.main.releaseBuildNumber {
            UserDefaults.standard.set(version, forKey: "last_release_version")
            UserDefaults.standard.set(build, forKey: "last_release_build")
        }
    }
    
}

private extension Bundle {
    var releaseVersionNumber: String? {
        return self.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var releaseBuildNumber: String? {
        return self.infoDictionary?["CFBundleVersion"] as? String
    }
}

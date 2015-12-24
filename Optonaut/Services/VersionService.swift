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
        let lastVersion = NSUserDefaults.standardUserDefaults().objectForKey("last_release_version") as? String
        let newVersion = NSBundle.mainBundle().releaseVersionNumber
        let lastBuild = NSUserDefaults.standardUserDefaults().objectForKey("last_release_build") as? String
        let newBuild = NSBundle.mainBundle().releaseBuildNumber
        return lastVersion != newVersion || lastBuild != newBuild
    }()
    
    static func updateToLatest() {
        if let version = NSBundle.mainBundle().releaseVersionNumber, build = NSBundle.mainBundle().releaseBuildNumber {
            NSUserDefaults.standardUserDefaults().setObject(version, forKey: "last_release_version")
            NSUserDefaults.standardUserDefaults().setObject(build, forKey: "last_release_build")
        }
    }
    
    static func onOutdatedApiVersion(errorCallback: () -> ()) {
        ApiService<EmptyResponse>.checkVersion().startWithFailed { error in
            if error.status == 404 {
                errorCallback()
            }
        }
    }
    
}

private extension NSBundle {
    var releaseVersionNumber: String? {
        return self.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var releaseBuildNumber: String? {
        return self.infoDictionary?["CFBundleVersion"] as? String
    }
}
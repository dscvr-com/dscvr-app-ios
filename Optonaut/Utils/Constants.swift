//
//  Constants.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/29/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import Device

enum EnvType {
    case Development
    case Staging
    case Production
}

let Env = EnvType.Development
//let Env = EnvType.Staging
//let Env = EnvType.Production

var StaticFilePath: String {
    switch Env {
    case .Development: return "http://optonaut-ios-beta-dev.s3.amazonaws.com"
    case .Staging: return "http://optonaut-ios-beta-staging.s3.amazonaws.com"
    case .Production: return "http://optonaut-ios-beta-production.s3.amazonaws.com"
    }
}

enum UserDefaultsKeys: String {
    case PersonIsLoggedIn = "person_is_logged_in"
    case PersonToken = "person_token"
    case PersonId = "person_id"
    case DebugEnabled = "debug_enabled"
    case LastReleaseVersion = "last_release_version"
}

enum NotificationKeys: String {
    case Logout = "logout"
}

let CameraIntrinsics: [Double] = {
    switch UIDevice.currentDevice().deviceType {
    case .IPhone6: return [4.854369, 0, 3, 0, 4.854369, 1.6875, 0, 0, 1]
    case .IPhone5S: return [4.854369, 0, 3, 0, 4.854369, 2.4, 0, 0, 1]
    default: return []
    }
}()
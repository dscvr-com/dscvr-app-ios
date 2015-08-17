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

enum PersonDefaultsKeys: String {
    case PersonIsLoggedIn = "person_is_logged_in"
    case PersonToken = "person_token"
    case PersonId = "person_id"
    case DebugEnabled = "debug_enabled"
}

enum NotificationKeys: String {
    case Logout = "logout"
}

let CameraIntrinsics: [Double] = {
    switch UIDevice.currentDevice().deviceType {
    case .IPhone6: return [4.854369, 0, 3, 0, 4.854369, 2.4, 0, 0, 1]
    case .IPhone5S: return [4.854369, 0, 3, 0, 4.854369, 2.4, 0, 0, 1]
    default: return []
    }
}()
//
//  DeviceTokenService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 19/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

class DeviceTokenService {
    
    static var deviceToken: String? {
        didSet {
            //updateServer()
        }
    }
    
    static func askForPermission() {
        if SessionService.isLoggedIn {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

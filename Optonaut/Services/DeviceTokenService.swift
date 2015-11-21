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
            updateServer()
        }
    }
    
    static func askForPermission() {
        if SessionService.isLoggedIn {
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
            UIApplication.sharedApplication().registerForRemoteNotifications()
        }
    }
    
    static func updateServer() {
        if let deviceToken = deviceToken where SessionService.isLoggedIn {
            ApiService<EmptyResponse>.post("persons/me/update-device-token", parameters: ["token": deviceToken])
                .start()
        }
    }
    
    
}
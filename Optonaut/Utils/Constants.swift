//
//  Constants.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/29/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation

enum UserDefaultsKeys: String {
    case UserIsLoggedIn = "user_is_logged_in"
    case UserToken = "user_token"
    case UserId = "user_id"
}

enum NotificationKeys: String {
    case Logout = "logout"
}

let IPhone6Intrinsics = [4.854369, 0, 3,
                         0, 4.854369, 2.4,
                         0, 0, 1]
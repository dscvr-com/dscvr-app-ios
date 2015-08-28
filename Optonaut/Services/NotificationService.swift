//
//  NotificationService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/27/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import Async

enum NotificationLevel {
    case Success
    case Info
    case Warning
    case Error
}

class NotificationService {
    
    private static let notification = CWStatusBarNotification()
    
    static func push(message: String, level: NotificationLevel, duration: Double = 3.0) {
        if notification.notificationIsShowing {
            notification.dismissNotificationWithCompletion {
                push(message, level: level, duration: duration)
            }
            return
        }
        
        notification.notificationStyle = .NavigationBarNotification
        notification.notificationAnimationInStyle = .Top
        notification.notificationAnimationOutStyle = .Top
        notification.notificationLabelBackgroundColor = levelToColor(level)
        notification.notificationLabelTextColor = .whiteColor()
        notification.notificationLabelFont = UIFont.robotoOfSize(15, withType: .Regular)
        
        Async.main {
            notification.displayNotificationWithMessage(message, forDuration: duration)
        }
    }
    
    private static func levelToColor(level: NotificationLevel) -> UIColor {
        switch level {
        case .Success: return UIColor(0x91CB3E)
        case .Info: return UIColor(0x1C77C3)
        case .Warning: return UIColor(0xFB8B24)
        case .Error: return BaseColor
        }
    }
    
}
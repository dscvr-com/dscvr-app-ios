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
    case success
    case info
    case warning
    case error
}

class NotificationService {
    
    fileprivate static let notification = CWStatusBarNotification()
    
    static func push(_ message: String, level: NotificationLevel, duration: Double = 3.0) {
        if notification.notificationIsShowing {
            notification.dismissNotificationWithCompletion {
                push(message, level: level, duration: duration)
            }
            return
        }
        
        notification.notificationStyle = .navigationBarNotification
        notification.notificationAnimationInStyle = .top
        notification.notificationAnimationOutStyle = .top
        notification.notificationLabelBackgroundColor = levelToColor(level)
        notification.notificationLabelTextColor = .white
        notification.notificationLabelFont = UIFont.robotoOfSize(15, withType: .Regular)
        
        Async.main {
            notification.displayNotificationWithMessage(message, forDuration: duration)
        }
    }
    
    fileprivate static func levelToColor(_ level: NotificationLevel) -> UIColor {
        switch level {
        case .success: return .Success
        case .info: return UIColor(0x1C77C3)
        case .warning: return UIColor(0xFB8B24)
        case .error: return UIColor.Accent
        }
    }
    
}

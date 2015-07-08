//
//  Utils.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/20/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

func baseColor() -> UIColor {
    return UIColor(0xef4836)
}

func setTabBarIcon(tabBarItem: UITabBarItem, icon: Icomoon) {
    tabBarItem.title = String.icomoonWithName(icon)
}
    
enum RoundedDurationType: String {
    case Seconds = "seconds"
    case Minutes = "minutes"
    case Hours = "hours"
    case Days = "days"
    case Weeks = "weeks"
}

struct RoundedDuration {
    
    var type: RoundedDurationType
    var value: Int
    
    init(date: NSDate) {
        let oneMinuteMark: NSTimeInterval = 60
        let oneHourMark: NSTimeInterval = oneMinuteMark * 60
        let oneDayMark: NSTimeInterval = oneHourMark * 24
        let oneWeekMark: NSTimeInterval = oneDayMark * 7
        let differenceInSeconds = -date.timeIntervalSinceNow
    
        switch differenceInSeconds {
        case 0...oneMinuteMark:
            type = .Seconds
            value = Int(differenceInSeconds)
        case oneMinuteMark...oneHourMark:
            type = .Minutes
            value = Int(differenceInSeconds / oneMinuteMark)
        case oneHourMark...oneDayMark:
            type = .Hours
            value = Int(differenceInSeconds / oneHourMark)
        case oneDayMark...oneWeekMark:
            type = .Days
            value = Int(differenceInSeconds / oneDayMark)
        default:
            type = .Weeks
            value = Int(differenceInSeconds / oneWeekMark)
        }
    }
    
    func shortDescription() -> String {
        return "\(value)\(Array(type.rawValue.characters)[0])"
    }
    
    func longDescription() -> String {
        let typeRaw = type.rawValue
        let typeString = value == 1 ? typeRaw.substringToIndex(advance(typeRaw.endIndex, -1)) : typeRaw
        return "\(value) \(typeString) ago"
    }
}

func isValidEmail(testStr: String) -> Bool {
    let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluateWithObject(testStr)
}
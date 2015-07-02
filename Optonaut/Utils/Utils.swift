//
//  Utils.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/20/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import FontAwesome

func baseColor() -> UIColor {
    return UIColor(red: 239.0 / 255, green: 72.0 / 255, blue: 54.0 / 255, alpha: 1)
}

func styleTabBarItem(tabBarItem: UITabBarItem, icon: FontAwesome) {
    tabBarItem.title = String.fontAwesomeIconWithName(icon)
}

func durationSince(date: NSDate) -> String {
    let oneMinuteMark: NSTimeInterval = 60
    let oneHourMark: NSTimeInterval = oneMinuteMark * 60
    let oneDayMark: NSTimeInterval = oneHourMark * 24
    let oneWeekMark: NSTimeInterval = oneDayMark * 7
    let differenceInSeconds = -date.timeIntervalSinceNow
    
    switch differenceInSeconds {
    case 0...oneMinuteMark: return "\(Int(differenceInSeconds))s"
    case oneMinuteMark...oneHourMark: return "\(Int(differenceInSeconds / oneMinuteMark))m"
    case oneHourMark...oneDayMark: return "\(Int(differenceInSeconds / oneHourMark))h"
    case oneDayMark...oneWeekMark: return "\(Int(differenceInSeconds / oneDayMark))d"
    default: return "\(Int(differenceInSeconds / oneWeekMark))w"
    }
}

func isValidEmail(testStr: String) -> Bool {
    let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluateWithObject(testStr)
}
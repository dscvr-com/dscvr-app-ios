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
//import ReactiveCocoa

func baseColor() -> UIColor {
    return UIColor(red: 239.0 / 255, green: 72.0 / 255, blue: 54.0 / 255, alpha: 1)
}

enum UserDefaultsKeys: String {
    case USER_IS_LOGGED_IN = "user_is_logged_in"
    case USER_TOKEN = "user_token"
    case USER_ID = "user_id"
}

func styleTabBarItem(tabBarItem: UITabBarItem, icon: FontAwesome) {
    tabBarItem.title = String.fontAwesomeIconWithName(icon)
}

func api() -> String {
    return "192.168.2.102:3000"
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

func isValidEmail(testStr:String) -> Bool {
    // println("validate calendar: \(testStr)")
    let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluateWithObject(testStr)
}

//// a struct that replaces the RAC macro
//struct RAC  {
//    var target : NSObject!
//    var keyPath : String!
//    var nilValue : AnyObject!
//    
//    init(_ target: NSObject!, _ keyPath: String, nilValue: AnyObject? = nil) {
//        self.target = target
//        self.keyPath = keyPath
//        self.nilValue = nilValue
//    }
//    
//    func assignSignal(signal : RACSignal) {
//        signal.setKeyPath(self.keyPath, onObject: self.target, nilValue: self.nilValue)
//    }
//}
//
//infix operator ~> { associativity left precedence 160 }
//func ~> (signal: RACSignal, rac: RAC) {
//    rac.assignSignal(signal)
//}
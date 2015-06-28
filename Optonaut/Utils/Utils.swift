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
import SwiftyJSON
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

func mapOptographFromJson(optographJson: JSON) -> Optograph {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"
    
    let user = User()
    user.id = optographJson["user"]["id"].intValue
    user.email = optographJson["user"]["email"].stringValue
    user.userName = optographJson["user"]["user_name"].stringValue
    
    let optograph = Optograph()
    optograph.id = optographJson["id"].intValue
    optograph.text = optographJson["text"].stringValue
    optograph.numberOfLikes = optographJson["number_of_likes"].intValue
    optograph.likedByUser = optographJson["liked_by_user"].boolValue
    optograph.createdAt = dateFormatter.dateFromString(optographJson["created_at"].stringValue)!
    optograph.user = user
    
    return optograph
}

func mapActivityFromJson(activityJson: JSON) -> Activity {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"
    
    let creator = User()
    creator.id = activityJson["creator"]["id"].intValue
    creator.email = activityJson["creator"]["email"].stringValue
    creator.userName = activityJson["creator"]["user_name"].stringValue
    
    let activity = Activity()
    activity.id = activityJson["id"].intValue
    activity.createdAt = dateFormatter.dateFromString(activityJson["created_at"].stringValue)!
    activity.creator = creator
    
    switch activityJson["type"].stringValue {
    case "like": activity.activityType = .Like
    case "follow": activity.activityType = .Follow
    default: activity.activityType = .Nil
    }
    
    if activityJson["optograph"].null != nil {
        let optograph = Optograph()
        optograph.id = activityJson["optograph"]["id"].intValue
        optograph.text = activityJson["optograph"]["text"].stringValue
        optograph.numberOfLikes = activityJson["optograph"]["number_of_likes"].intValue
        optograph.likedByUser = activityJson["optograph"]["liked_by_user"].boolValue
        optograph.createdAt = dateFormatter.dateFromString(activityJson["optograph"]["created_at"].stringValue)!
        
        activity.optograph = optograph
    }
    
    return activity
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
//
//  Utils.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/20/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa
import SQLite

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

func uuid() -> UUID {
    return NSUUID().UUIDString.lowercaseString
}

func isValidEmail(email: String) -> Bool {
    let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailTest.evaluateWithObject(email)
}

func isValidPassword(password: String) -> Bool {
    return password.characters.count >= 5
}

func isValidUserName(userName: String) -> Bool {
    let userNameRegEx = "^[a-zA-Z0-9_]+$"
    let userNameTest = NSPredicate(format:"SELF MATCHES %@", userNameRegEx)
    return userNameTest.evaluateWithObject(userName)
}

func identity<T>(el: T) -> T {
    return el
}

func calcTextHeight(text: String, withWidth width: CGFloat) -> CGFloat {
    let attributes = [NSFontAttributeName: UIFont.robotoOfSize(13, withType: .Light)]
    let textAS = NSAttributedString(string: text, attributes: attributes)
    let tmpSize = CGSize(width: width, height: 100000)
    let textRect = textAS.boundingRectWithSize(tmpSize, options: [.UsesFontLeading, .UsesLineFragmentOrigin], context: nil)
    
    return textRect.height
}

class NotificationSignal {
    
    private let (signal, sink) = Signal<Void, NoError>.pipe()
    
    func notify() {
        sendNext(sink, ())
    }
    
    func subscribe(fn: () -> Void) {
        signal.observe(next: fn)
    }
    
}

public func <(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == NSComparisonResult.OrderedAscending
}

public func >(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == NSComparisonResult.OrderedDescending
}

public func ==(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == NSComparisonResult.OrderedSame
}

extension NSDate: Comparable { }

extension String {
    func stringByAppendingPathComponent(path: String) -> String {
        let nsSt = self as NSString
        return nsSt.stringByAppendingPathComponent(path)
    }
}

extension NSBundle {
    var releaseVersionNumber: String? {
        return self.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

infix operator <-- {
    associativity left
    precedence 135
    assignment
}

public func <--<V : Value>(column: Expression<V>, value: Expression<V>) -> Setter {
    return column <- value
}
public func <--<V : Value>(column: Expression<V>, value: V) -> Setter {
    return column <- value
}
public func <--<V : Value>(column: Expression<V?>, value: Expression<V>) -> Setter {
    return column <- value
}
public func <--<V : Value>(column: Expression<V?>, value: Expression<V?>) -> Setter {
    return column <- value
}
public func <--<V : Value>(column: Expression<V?>, value: V?) -> Setter {
    return column <- value
}


infix operator ==- {
    associativity left
    precedence 135
}

public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V?>, rhs: V?) -> Expression<Bool?> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: V?, rhs: Expression<V?>) -> Expression<Bool?> {
    return lhs == rhs
}
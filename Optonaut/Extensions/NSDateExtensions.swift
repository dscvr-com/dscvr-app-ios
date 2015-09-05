//
//  NSDateExtensions.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/27/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

private let rfc3339DateFormatter1: NSDateFormatter = {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"
    dateFormatter.timeZone = .localTimeZone()
    dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    return dateFormatter
    }()

private let rfc3339DateFormatter2: NSDateFormatter = {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
    dateFormatter.timeZone = .localTimeZone()
    dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    return dateFormatter
    }()

public extension NSDate {
    
    public static func fromRFC3339String(str: String) -> NSDate? {
        if let date = rfc3339DateFormatter1.dateFromString(str) {
            return date
        } else if let date = rfc3339DateFormatter2.dateFromString(str) {
            return date
        }
        return nil
    }
    
    public func toRFC3339String() -> String {
        return rfc3339DateFormatter1.stringFromDate(self)
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

extension NSDate {

    private enum RoundedDuration: String {
        case Seconds = "seconds"
        case Minutes = "minutes"
        case Hours = "hours"
        case Days = "days"
        case Weeks = "weeks"
    }
    
    private func calc() -> (Int, RoundedDuration) {
        let oneMinuteMark: NSTimeInterval = 60
        let oneHourMark: NSTimeInterval = oneMinuteMark * 60
        let oneDayMark: NSTimeInterval = oneHourMark * 24
        let oneWeekMark: NSTimeInterval = oneDayMark * 7
        let differenceInSeconds = -self.timeIntervalSinceNow
    
        if differenceInSeconds < 0 {
            return(0, .Seconds)
        }
    
        switch differenceInSeconds {
        case 0...oneMinuteMark:
            return(Int(differenceInSeconds), .Seconds)
        case oneMinuteMark...oneHourMark:
            return(Int(differenceInSeconds / oneMinuteMark), .Minutes)
        case oneHourMark...oneDayMark:
            return(Int(differenceInSeconds / oneHourMark), .Hours)
        case oneDayMark...oneWeekMark:
            return(Int(differenceInSeconds / oneDayMark), .Days)
        default:
            return(Int(differenceInSeconds / oneWeekMark), .Weeks)
        }
    }
    
    var shortDescription: String {
        let (value, type) = calc()
        return "\(value)\(Array(type.rawValue.characters)[0])"
    }
    
    var longDescription: String {
        let (value, type) = calc()
        let typeRaw = type.rawValue
        let typeString = value == 1 ? typeRaw.substringToIndex(typeRaw.endIndex.advancedBy(-1)) : typeRaw
        return "\(value) \(typeString) ago"
    }
}
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

extension NSDate {
    
    static func fromRFC3339String(str: String) -> NSDate? {
        if let date = rfc3339DateFormatter1.dateFromString(str) {
            return date
        } else if let date = rfc3339DateFormatter2.dateFromString(str) {
            return date
        }
        return nil
    }
    
    func toRFC3339String() -> String {
        return rfc3339DateFormatter1.stringFromDate(self)
    }
    
}
//
//  NSDateTransform.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/9/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

public class NSDateTransform: TransformType {
    public typealias Object = NSDate
    public typealias JSON = String
    
    let dateFormatter = NSDateFormatter()
    
    public init() {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    }
    
    public func transformFromJSON(value: AnyObject?) -> NSDate? {
        if let str = value as? String {
            return dateFormatter.dateFromString(str)
        }
        return nil
    }
    
    public func transformToJSON(value: NSDate?) -> String? {
        if let value = value {
            return dateFormatter.stringFromDate(value)
        }
        return nil
    }
}
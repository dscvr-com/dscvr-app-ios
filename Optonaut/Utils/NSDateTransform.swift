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
    
    public func transformFromJSON(value: AnyObject?) -> NSDate? {
        if let str = value as? String {
            return NSDate.fromRFC3339String(str)
        }
        return nil
    }
    
    public func transformToJSON(value: NSDate?) -> String? {
        if let date = value {
            return date.toRFC3339String()
        }
        return nil
    }
}

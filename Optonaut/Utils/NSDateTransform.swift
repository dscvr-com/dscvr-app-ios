//
//  NSDateTransform.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/9/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

open class NSDateTransform: TransformType {
    public typealias Object = Date
    public typealias JSON = String
    
    open func transformFromJSON(_ value: Any?) -> Date? {
        if let str = value as? String {
            return Date.fromRFC3339String(str)
        }
        return nil
    }
    
    open func transformToJSON(_ value: Date?) -> String? {
        if let date = value {
            return date.toRFC3339String()
        }
        return nil
    }
}

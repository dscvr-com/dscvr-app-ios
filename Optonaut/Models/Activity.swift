//
//  Activity.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/27/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

enum ActivityType: String {
    case Like = "star"
    case Follow = "follow"
    case Nil = ""
}

struct Activity: Model {
    var id: Int
    var creator: Person?
    var receiver: Person?
    var optograph: Optograph?
    var createdAt: NSDate
    var isRead: Bool
    var activityType: ActivityType
}

extension Activity: Mappable {
    
    static func newInstance() -> Mappable {
        return Activity(
            id: 0,
            creator: nil,
            receiver: nil,
            optograph: nil,
            createdAt: NSDate(),
            isRead: false,
            activityType: .Nil
        )
    }
    
    mutating func mapping(map: Map) {
        let typeTransform = TransformOf<ActivityType, String>(
            fromJSON: { (value: String?) -> ActivityType? in
                switch value! {
                case "star": return .Like
                case "follow": return .Follow
                default: return .Nil
                }
            },
            toJSON: { (value: ActivityType?) -> String? in
                return value!.rawValue
            }
        )
        
        id              <- map["id"]
        creator         <- map["creator"]
        receiver        <- map["receiver"]
        optograph       <- map["optograph"]
        createdAt       <- (map["created_at"], NSDateTransform())
        isRead          <- map["is_read"]
        activityType    <- (map["type"], typeTransform)
    }
    
}
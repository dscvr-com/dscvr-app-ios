//
//  Activity.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/27/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

enum ActivityType: String {
    case Like = "star"
    case Follow = "follow"
    case Nil = ""
}

class Activity: Object, Model {
    dynamic var id = 0
    dynamic var creator: Person?
    dynamic var receiver: Person?
    dynamic var optograph: Optograph?
    dynamic var createdAt = NSDate()
    dynamic var isRead = false
    var activityType: ActivityType = .Nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Activity: Mappable {
    
    static func newInstance() -> Mappable {
        return Activity()
    }
    
    func mapping(map: Map) {
//        let typeTransform = TransformOf<ActivityType, String>(
//            fromJSON: { (value: String?) -> ActivityType? in
//                switch value! {
//                case "star": return .Like
//                case "follow": return .Follow
//                default: return .Nil
//                }
//            },
//            toJSON: { (value: ActivityType?) -> String? in
//                return value!.rawValue
//            }
//        )
        
        id              <- map["id"]
        creator         <- map["creator"]
        receiver        <- map["receiver"]
        optograph       <- map["optograph"]
        createdAt       <- (map["created_at"], NSDateTransform())
        isRead          <- map["is_read"]
//        activityType    <- (map["type"], typeTransform)
    }
    
}
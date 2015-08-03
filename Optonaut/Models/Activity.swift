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
    case Like = "like"
    case Follow = "follow"
    case Nil = ""
}

class Activity: Object, Model {
    dynamic var id = 0
    dynamic var creator: User?
    dynamic var receiver: User?
    dynamic var optograph: Optograph?
    dynamic var createdAt = NSDate()
    dynamic var readByUser = false
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
        let typeTransform = TransformOf<ActivityType, String>(
            fromJSON: { (value: String?) -> ActivityType? in
                switch value! {
                case "like": return .Like
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
        readByUser      <- map["read_by_user"]
        activityType    <- (map["type"], typeTransform)
    }
    
}
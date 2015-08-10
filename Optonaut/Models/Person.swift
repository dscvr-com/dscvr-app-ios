//
//  User.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class Person: Object, Model {
    dynamic var id = 0
    dynamic var email = ""
    dynamic var fullName = ""
    dynamic var userName = ""
    dynamic var description_ = ""
    dynamic var followersCount = 0
    dynamic var followedCount = 0
    dynamic var isFollowed = false
    dynamic var createdAt = NSDate()
    
    let optographs = List<Optograph>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Person: Mappable {
    
    func mapping(map: Map) {
        id                  <- map["id"]
        email               <- map["email"]
        fullName            <- map["full_name"]
        userName            <- map["user_name"]
        description_        <- map["description"]
        followersCount      <- map["followers_count"]
        followedCount       <- map["followed_count"]
        isFollowed          <- map["is_followed"]
        createdAt           <- (map["created_at"], NSDateTransform())
        
        var arr = [Optograph]()
        arr <- map["optographs"]
        
        optographs.removeAll()
        for optograph in arr {
            optographs.append(optograph)
        }
    }
    
    static func newInstance() -> Mappable {
        return Person()
    }
    
}
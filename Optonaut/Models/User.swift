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

class User: Object, Model {
    dynamic var id = 0
    dynamic var email = ""
    dynamic var name = ""
    dynamic var userName = ""
    dynamic var bio = ""
    dynamic var numberOfFollowers = 0
    dynamic var numberOfFollowings = 0
    dynamic var numberOfOptographs = 0
    dynamic var isFollowing = false
    dynamic var createdAt = NSDate()
    
    let optographs = List<Optograph>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

extension User: Mappable {
    
    func mapping(map: Map) {
        id                  <- map["id"]
        email               <- map["email"]
        name                <- map["name"]
        userName            <- map["user_name"]
        bio                 <- map["bio"]
        numberOfFollowers   <- map["number_of_followers"]
        numberOfFollowings  <- map["number_of_followings"]
        numberOfFollowings  <- map["number_of_followings"]
        isFollowing         <- map["is_following"]
        createdAt           <- (map["created_at"], NSDateTransform())
        
        var arr = [Optograph]()
        arr <- map["optographs"]
        
        optographs.removeAll()
        for optograph in arr {
            optographs.append(optograph)
        }
    }
    
    static func newInstance() -> Mappable {
        return User()
    }
    
}
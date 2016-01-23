//
//  PersonApiModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 22/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct PersonApiModel: Mappable {
    
    var ID: UUID = ""
    var createdAt: NSDate = NSDate()
    var email: String? = nil
    var displayName: String = ""
    var userName: String = ""
    var text: String = ""
    var followersCount: Int = 0
    var followedCount: Int = 0
    var isFollowed: Bool = false
    
    init() {}
    
    init?(_ map: Map){}
    
    mutating func mapping(map: Map) {
        ID                  <- map["id"]
        email               <- map["email"]
        displayName         <- map["display_name"]
        userName            <- map["user_name"]
        text                <- map["text"]
        followersCount      <- map["followers_count"]
        followedCount       <- map["followed_count"]
        isFollowed          <- map["is_followed"]
        createdAt           <- (map["created_at"], NSDateTransform())
    }
    
    func toModel() -> Person {
        var model = Person.newInstance()
        model.ID = ID
        model.createdAt = createdAt
        model.email = email
        model.displayName = displayName
        model.userName = userName
        model.text = text
        model.followersCount = followersCount
        model.followedCount = followedCount
        model.isFollowed = isFollowed
        return model
    }
}
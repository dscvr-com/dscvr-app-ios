//
//  PersonApiModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 22/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct PersonApiModel: ApiModel, Mappable {
    
    var ID: UUID = ""
    var createdAt: NSDate = NSDate()
    var updatedAt: NSDate = NSDate()
    var email: String? = nil
    var displayName: String = ""
    var userName: String = ""
    var text: String = ""
    var optographsCount: Int = 0
    var followersCount: Int = 0
    var followedCount: Int = 0
    var isFollowed: Bool = false
    var avatarAssetID: UUID = ""
    var eliteUser:Int = 0
    
    init() {}
    
    init?(_ map: Map){}
    
    mutating func mapping(map: Map) {
        ID                  <- map["id"]
        createdAt           <- (map["created_at"], NSDateTransform())
        updatedAt           <- (map["updated_at"], NSDateTransform())
        email               <- map["email"]
        displayName         <- map["display_name"]
        userName            <- map["user_name"]
        text                <- map["text"]
        optographsCount     <- map["optographs_count"]
        followersCount      <- map["followers_count"]
        followedCount       <- map["followed_count"]
        isFollowed          <- map["is_followed"]
        avatarAssetID       <- map["avatar_asset_id"]
        eliteUser           <- map["elite_status"]
    }
}
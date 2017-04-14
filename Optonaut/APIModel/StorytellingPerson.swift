//
//  StorytellingPerson.swift
//  DSCVR
//
//  Created by Thadz on 25/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct StorytellingPerson: Mappable {
    var id: String = ""
    var created_at:  String = ""
    var deleted_at: String = ""
    var wants_newsletter: Bool = false
    var display_name: String = ""
    var user_name: String = ""
    var text: String = ""
    var onboarding_version: String = ""
    var elite_status: String = ""
    var avatar_asset_id: String = ""
    var optographs: String = ""
    var optographs_count: String = ""
    var followers_count: String = ""
    var followed_count: String = ""
    var is_followed: Bool = false
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        id <- map["id"]
        created_at <- map["created_at"]
        deleted_at <- map["deleted_at"]
        wants_newsletter <- map["wants_newsletter"]
        display_name <- map["display_name"]
        user_name <- map["user_name"]
        text <- map["text"]
        onboarding_version <- map["onboarding_version"]
        elite_status <- map["elite_status"]
        avatar_asset_id <- map["avatar_asset_id"]
        optographs <- map["optographs"]
        optographs_count <- map["optographs_count"]
        followers_count <- map["followers_count"]
        followed_count <- map["followed_count"]
        is_followed <- map["is_followed"]
    }
}

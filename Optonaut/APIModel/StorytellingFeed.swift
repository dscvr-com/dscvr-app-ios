//
//  StorytellingFeed.swift
//  DSCVR
//
//  Created by Thadz on 25/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct StorytellingFeed: Mappable {
    var placeholder: String = ""
    var id:  String = ""
    var created_at: String = ""
    var updated_at: String = ""
    var deleted_at: String = ""
    var stitcher_version: String = ""
    var text: String = ""
    var views_count: String = ""
    var optograph_type: String = ""
    var optograph_platform: String = ""
    var optograph_model: String = ""
    var optograph_make: String = ""
    var optograph_daemon: String = ""
    var is_staff_pick: Bool = false
    var share_alias: String = ""
    var is_private: Bool = false
    var direction_phi: String = ""
    var direction_theta: String = ""
    var is_published: Bool = false
    var placeholder_texture_asset_id: String = ""
    var left_texture_asset_id: String = ""
    var right_texture_asset_id: String = ""
    var location: StorytellingLocation?
    var person: StorytellingPerson?
    var stars_count: String = ""
    var comments_count: String = ""
    var is_starred: Bool = false
    var hashtag_string: String = ""
    var story: StoryObject?
    
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        placeholder <- map["placeholder"]
        id <- map["id"]
        created_at <- map["created_at"]
        updated_at <- map["updated_at"]
        deleted_at <- map["deleted_at"]
        stitcher_version <- map["stitcher_version"]
        views_count <- map["teviews_countxt"]
        optograph_type <- map["optograph_type"]
        optograph_platform <- map["optograph_platform"]
        optograph_model <- map["optograph_model"]
        optograph_make <- map["optograph_make"]
        optograph_daemon <- map["optograph_daemon"]
        is_staff_pick <- map["is_staff_pick"]
        share_alias <- map["share_alias"]
        is_private <- map["is_private"]
        direction_phi <- map["direction_phi"]
        direction_theta <- map["direction_theta"]
        is_published <- map["is_published"]
        placeholder_texture_asset_id <- map["placeholder_texture_asset_id"]
        left_texture_asset_id <- map["left_texture_asset_id"]
        right_texture_asset_id <- map["right_texture_asset_id"]
        location <- map["location"]
        person <- map["person"]
        stars_count <- map["stars_count"]
        comments_count <- map["comments_count"]
        is_starred <- map["is_starred"]
        hashtag_string <- map["hashtag_string"]
        story <- map["story"]
    }
}
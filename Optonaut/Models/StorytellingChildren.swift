//
//  StorytellingChildren.swift
//  DSCVR
//
//  Created by Dongie on 03/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct StorytellingChildren: Mappable {
    var story_object_id: String = ""
    var story_object_story_id:  String = ""
    var story_object_media_type: String = ""
    var story_object_media_face: String = ""
    var story_object_media_description: String = ""
    var story_object_media_additional_data: String = ""
    var story_object_position: [String] = []
    var story_object_rotation: [String] = []
    var story_object_created_at: String = ""
    var story_object_deleted_at: String = ""
    var story_object_media_filename: String = ""
    var story_object_media_fileurl: String = ""
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        story_object_id              <- map["story_object_id"]
        story_object_story_id                 <- map["story_object_story_id"]
        story_object_media_type  <- map["story_object_media_type"]
        story_object_media_face  <- map["story_object_media_face"]
        story_object_media_description  <- map["story_object_media_description"]
        story_object_media_additional_data  <- map["story_object_media_additional_data"]
        story_object_position  <- map["story_object_position"]
        story_object_rotation  <- map["story_object_rotation"]
        story_object_created_at  <- map["story_object_created_at"]
        story_object_deleted_at  <- map["story_object_deleted_at"]
        story_object_media_filename  <- map["story_object_media_filename"]
        story_object_media_fileurl  <- map["story_object_media_fileurl"]
    }
}
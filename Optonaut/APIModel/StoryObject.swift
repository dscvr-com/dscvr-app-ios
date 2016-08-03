//
//  StoryObject.swift
//  DSCVR
//
//  Created by Thadz on 03/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct StoryObject: Mappable {
    var story_id: String = ""
    var story_optograph_id:  String = ""
    var story_person_id: String = ""
    var story_created_at: String = ""
    var story_updated_at: String = ""
    var story_deleted_at: String = ""
    var children: [String] = []
    var child: [String] = []
    var story_object_created_at: String = ""
    var story_object_deleted_at: String = ""
    var story_object_media_filename: String = ""
    var story_object_media_fileurl: String = ""
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        story_id              <- map["story_object_id"]
        story_optograph_id                 <- map["story_object_story_id"]
        story_person_id  <- map["story_object_media_type"]
        story_created_at  <- map["story_object_media_face"]
        story_updated_at  <- map["story_object_media_description"]
        story_deleted_at  <- map["story_object_media_additional_data"]
        children  <- map["story_object_position"]
        story_object_rotation  <- map["story_object_rotation"]
        story_object_created_at  <- map["story_object_created_at"]
        story_object_deleted_at  <- map["story_object_deleted_at"]
        story_object_media_filename  <- map["story_object_media_filename"]
        story_object_media_fileurl  <- map["story_object_media_fileurl"]
    }
}
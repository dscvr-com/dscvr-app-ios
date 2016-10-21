//
//  StorytellingChildren.swift
//  DSCVR
//
//  Created by Thadz on 03/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct StorytellingChildren: ApiModel,Mappable {
    
    var ID:UUID = ""
    var createdAt:NSDate = NSDate()
    var updatedAt:NSDate = NSDate()
    var deletedAt:NSDate? = nil
    var storyID: String = ""
    var mediaType: String = ""
    var mediaFace: String = ""
    var mediaDescription: String = ""
    var mediaAdditionalData: String = ""
    var objectPosition: String = ""
    var objectRotation: String = ""
    var objectMediaFilename: String = ""
    var objectMediaFileUrl: String = ""
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        
        var opArray: [String] = []
        var orArray: [String] = []
        
        ID                    <- map["story_object_id"]
        storyID               <- map["story_object_story_id"]
        mediaType             <- map["story_object_media_type"]
        mediaFace             <- map["story_object_media_face"]
        mediaDescription      <- map["story_object_media_description"]
        mediaAdditionalData   <- map["story_object_media_additional_data"]
        opArray               <- map["story_object_position"]
        orArray               <- map["story_object_rotation"]
        createdAt             <- map["story_object_created_at"]
        deletedAt             <- map["story_object_deleted_at"]
        updatedAt             <- map["story_object_updated_at"]
        objectMediaFilename   <- map["story_object_media_filename"]
        objectMediaFileUrl    <- map["story_object_media_fileurl"]
        
        if opArray.count != 0 {
            objectPosition = opArray.joinWithSeparator(",")
        }
        
        if orArray.count != 0 {
            objectRotation = orArray.joinWithSeparator(",")
        }
    }
}

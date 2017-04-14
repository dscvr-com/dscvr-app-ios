//
//  ChildNameResponse.swift
//  DSCVR
//
//  Created by Thadz on 29/09/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct ChildNameResponse: Mappable {
    var story_object_id: String = ""
    var story_object_media_filename:  String = ""
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        story_object_id              <- map["story_object_id"]
        story_object_media_filename                 <- map["story_object_media_filename"]
    }
}

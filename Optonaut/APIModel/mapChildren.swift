//
//  mapChildren.swift
//  DSCVR
//
//  Created by robert john alkuino on 8/5/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct mapChildren: Mappable {
    var children:[StorytellingChildren]?
    var story_id: String = ""
    var story_optograph_id: String = ""
    var story_person_id: String = ""
    var story_created_at: String = ""
    var story_updated_at: String = ""
    var story_deleted_at: String = ""
    
    init?(_ map: Map) {
    }
    
    mutating func mapping(map: Map) {
        children              <- map["children"]
    }
}

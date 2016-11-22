//
//  MultiformDataInfo.swift
//  DSCVR
//
//  Created by Thadz on 29/09/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct MultiformDataInfo: Mappable {
    var story_id: String = ""
    var children: [StorytellingChildren]?
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        story_id              <- map["story_id"]
        children              <- map["children"]
    }
}

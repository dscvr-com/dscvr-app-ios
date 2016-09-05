//
//  StorytellingMerged.swift
//  DSCVR
//
//  Created by Thadz on 25/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct StorytellingMerged: Mappable {
    var feed: [StorytellingFeed] = []
    var user: [StorytellingFeed] = []
    
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        feed <- map["feed"]
        user <- map ["you"]
    }
}
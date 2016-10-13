//
//  mapChildren.swift
//  DSCVR
//
//  Created by robert john alkuino on 8/5/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct mapChildren: ApiModel, Mappable {
    
    var ID:UUID = ""
    var createdAt:NSDate = NSDate()
    var updatedAt:NSDate = NSDate()
    var deletedAt:NSDate = NSDate()
    var optographID = ""
    var personID = ""
    var children:[StorytellingChildren]?
    
    init() {}
    init?(_ map: Map) {
    }
    
    mutating func mapping(map: Map) {
        ID              <- map["id"]
        createdAt       <- (map["created_at"], NSDateTransform())
        updatedAt       <- (map["updated_at"], NSDateTransform())
        updatedAt       <- (map["deleted_at"], NSDateTransform())
        personID        <- map["person_id"]
        optographID     <- map["optograph_id"]
        children        <- map["children"]
    }
}

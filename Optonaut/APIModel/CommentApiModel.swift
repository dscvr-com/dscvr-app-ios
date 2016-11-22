//
//  CommentApiModel.swift
//  DSCVR
//
//  Created by robert john alkuino on 9/15/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct CommentApiModel: ApiModel, Mappable {
    
    var ID: UUID = ""
    var createdAt: NSDate = NSDate()
    var updatedAt: NSDate = NSDate()
    var text: String = ""
    var person: PersonApiModel = PersonApiModel()
    var optograph: Optograph?
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        ID          <- map["id"]
        createdAt   <- (map["created_at"], NSDateTransform())
        updatedAt   <- (map["updated_at"], NSDateTransform())
        text        <- map["text"]
        person      <- map["person"]
        optograph   <- map["optograph"]
    }
}
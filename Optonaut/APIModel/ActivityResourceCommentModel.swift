//
//  ActivityResourceCommentModel.swift
//  DSCVR
//
//  Created by robert john alkuino on 9/20/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct ActivityResourceCommentModel: Mappable {
    var ID: UUID = ""
    var optograph:OptographApiModel?
    var causingPerson:PersonApiModel = PersonApiModel()
    //var comment: Comment
    
    init() {}
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        ID              <- map["id"]
        optograph       <- map["optograph"]
        causingPerson   <- map["causing_person"]
       // comment         <- map["comment"]
    }
}

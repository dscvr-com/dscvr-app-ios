//
//  ActivityResourceStarModel.swift
//  DSCVR
//
//  Created by robert john alkuino on 7/19/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct ActivityResourceStarModel: Mappable {
    var ID: UUID = ""
    var optograph:OptographApiModel = OptographApiModel()
    var causingPerson:PersonApiModel = PersonApiModel()
    
    init() {}
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        ID              <- map["id"]
        optograph       <- map["optograph"]
        causingPerson   <- map["causing_person"]
    }
}
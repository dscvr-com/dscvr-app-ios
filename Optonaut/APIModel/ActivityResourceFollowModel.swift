//
//  ActivityResourceFollowModel.swift
//  DSCVR
//
//  Created by robert john alkuino on 7/19/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct ActivityResourceFollowModel: Mappable {
    var ID: UUID = ""
    var causingPerson:PersonApiModel = PersonApiModel()
    
    init() {}
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        ID              <- map["id"]
        causingPerson   <- map["causing_person"]
    }
}


//
//  StorytellingResponse.swift
//  DSCVR
//
//  Created by Thadz on 03/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct StorytellingResponse: Mappable {
    var status: String = ""
    var message:  String = ""
    var data: String = ""
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        status              <- map["status"]
        message                 <- map["message"]
        data  <- map["data"]
    }
}

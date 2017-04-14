//
//  ChildResponse.swift
//  DSCVR
//
//  Created by Thadz on 29/09/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct ChildResponse: Mappable {
    var status: String = ""
    var message:  String = ""
    var data: MultiformDataInfo?
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        status              <- map["status"]
        message                 <- map["message"]
        data  <- map["data"]
    }
}

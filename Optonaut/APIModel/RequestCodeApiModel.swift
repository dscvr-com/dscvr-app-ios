//
//  RequestCodeApiModel.swift
//  DSCVR
//
//  Created by robert john alkuino on 7/1/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct RequestCodeApiModel: Mappable {
    var status: String = ""
    var message:  String = ""
    var request_text: String = ""
    var prompt: String = ""
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        status              <- map["status"]
        message                 <- map["message"]
        request_text  <- map["request_text"]
        prompt  <- map["prompt"]
    }
}

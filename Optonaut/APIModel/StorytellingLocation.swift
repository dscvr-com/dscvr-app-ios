//
//  StorytellingLocation.swift
//  DSCVR
//
//  Created by Thadz on 25/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct StorytellingLocation: Mappable {
    var id: String = ""
    var created_at: String = ""
    var updated_at: String = ""
    var deleted_at: String = ""
    var latitude: String = ""
    var longitude: String = ""
    var text: String = ""
    var country: String = ""
    var country_short: String = ""
    var place: String = ""
    var region: String = ""
    var poi: Bool = false
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
//        status              <- map["status"]
//        message                 <- map["message"]
//        data  <- map["data"]
        
        id <- map["id"]
        created_at <- map["created_at"]
        updated_at <- map["updated_at"]
        deleted_at <- map["deleted_at"]
        latitude <- map["latitude"]
        longitude <- map["longitude"]
        text <- map["text"]
        country <- map["country"]
        country_short <- map["country_short"]
        place <- map["place"]
        region <- map["region"]
        poi <- map["poi"]
    }
}

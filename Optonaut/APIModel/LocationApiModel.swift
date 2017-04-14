//
//  LocationApiModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 22/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct LocationApiModel: ApiModel, Mappable {
    
    var ID: UUID = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var text: String = ""
    var country: String = ""
    var countryShort: String = ""
    var place: String = ""
    var region: String = ""
    var POI: Bool = false
    var latitude: Double = 0
    var longitude: Double = 0
    
    init() {}
    
    init?(map: Map){}
    
    mutating func mapping(map: Map) {
        ID              <- map["id"]
        createdAt       <- (map["created_at"], NSDateTransform())
        updatedAt       <- (map["updated_at"], NSDateTransform())
        text            <- map["text"]
        country         <- map["country"]
        countryShort    <- map["country_short"]
        place           <- map["place"]
        region          <- map["region"]
        POI             <- map["poi"]
        latitude        <- map["latitude"]
        longitude       <- map["longitude"]
    }
}

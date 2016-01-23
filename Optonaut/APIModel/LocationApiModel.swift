//
//  LocationApiModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 22/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct LocationApiModel: Mappable {
    
    var ID: UUID = ""
    var createdAt: NSDate = NSDate()
    var text: String = ""
    var country: String = ""
    var countryShort: String = ""
    var place: String = ""
    var region: String = ""
    var POI: Bool = false
    var latitude: Double = 0
    var longitude: Double = 0
    
    init() {}
    
    init?(_ map: Map){}
    
    mutating func mapping(map: Map) {
        ID              <- map["id"]
        createdAt       <- (map["created_at"], NSDateTransform())
        text            <- map["text"]
        country         <- map["country"]
        countryShort    <- map["country_short"]
        place           <- map["place"]
        region          <- map["region"]
        POI             <- map["poi"]
        latitude        <- map["latitude"]
        longitude       <- map["longitude"]
    }
    
    func toModel() -> Location {
        var model = Location.newInstance()
        model.ID = ID
        model.createdAt = createdAt
        model.country = country
        model.countryShort = countryShort
        model.place = place
        model.region = region
        model.POI = POI
        model.latitude = latitude
        model.longitude = longitude
        return model
    }
}
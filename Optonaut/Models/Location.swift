//
//  Location.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper

struct Location: Model {
    var id: UUID
    var text: String
    var createdAt: NSDate
    var latitude: Double
    var longitude: Double
}

extension Location: Mappable {
    
    static func newInstance() -> Mappable {
        return Location(
            id: uuid(),
            text: "",
            createdAt: NSDate(),
            latitude: 0,
            longitude: 0
        )
    }
    
    mutating func mapping(map: Map) {
        id              <- map["id"]
        text            <- map["text"]
        createdAt       <- (map["created_at"], NSDateTransform())
        latitude        <- map["latitude"]
        longitude       <- map["longitude"]
    }
    
}

//
//  Location.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper

struct Location: Model {
    var ID: UUID
    var createdAt: NSDate
    var text: String
    var country: String
    var countryShort: String
    var place: String
    var region: String
    var POI: Bool
    var latitude: Double
    var longitude: Double
    
    static func newInstance() -> Location {
        return Location(
            ID: uuid(),
            createdAt: NSDate(),
            text: "",
            country: "",
            countryShort: "",
            place: "",
            region: "",
            POI: false,
            latitude: 0,
            longitude: 0
        )
    }
    
}

func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.ID == rhs.ID
}

extension Location: Mappable {
    
    init?(_ map: Map){
        self = Location.newInstance()
    }
    
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
}

extension Location: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return LocationSchema
    }
    
    static func table() -> SQLiteTable {
        return LocationTable
    }
    
    static func fromSQL(row: SQLiteRow) -> Location {
        return Location(
            ID: row[LocationSchema.ID],
            createdAt: row[LocationSchema.createdAt],
            text: row[LocationSchema.text],
            country: row[LocationSchema.country],
            countryShort: row[LocationSchema.countryShort],
            place: row[LocationSchema.place],
            region: row[LocationSchema.region],
            POI: row[LocationSchema.POI],
            latitude: row[LocationSchema.latitude],
            longitude: row[LocationSchema.longitude]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            LocationSchema.ID <-- ID,
            LocationSchema.createdAt <-- createdAt,
            LocationSchema.text <-- text,
            LocationSchema.country <-- country,
            LocationSchema.countryShort <-- countryShort,
            LocationSchema.place <-- place,
            LocationSchema.region <-- region,
            LocationSchema.POI <-- POI,
            LocationSchema.latitude <-- latitude,
            LocationSchema.longitude <-- longitude
        ]
    }
    
}

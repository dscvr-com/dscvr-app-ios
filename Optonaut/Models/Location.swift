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
    var updatedAt: NSDate
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
            updatedAt: NSDate(),
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

extension Location: MergeApiModel {
    typealias AM = LocationApiModel
    
    mutating func mergeApiModel(apiModel: LocationApiModel) {
        ID = apiModel.ID
        createdAt = apiModel.createdAt
        updatedAt = apiModel.updatedAt
        country = apiModel.country
        countryShort = apiModel.countryShort
        place = apiModel.place
        region = apiModel.region
        POI = apiModel.POI
        latitude = apiModel.latitude
        longitude = apiModel.longitude
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
            updatedAt: row[LocationSchema.updatedAt],
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
            LocationSchema.updatedAt <-- updatedAt,
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

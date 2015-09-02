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
    
    static func newInstance() -> Location {
        return Location(
            id: uuid(),
            text: "",
            createdAt: NSDate(),
            latitude: 0,
            longitude: 0
        )
    }
    
}

extension Location: Mappable {
    
    init?(_ map: Map){
        self = Location.newInstance()
    }
    
    mutating func mapping(map: Map) {
        id              <- map["id"]
        text            <- map["text"]
        createdAt       <- (map["created_at"], NSDateTransform())
        latitude        <- map["latitude"]
        longitude       <- map["longitude"]
    }
}

extension Location: SQLiteModel {
    
    static func fromSQL(row: SQLiteRow) -> Location {
        return Location(
            id: row[LocationSchema.id],
            text: row[LocationSchema.text],
            createdAt: row[LocationSchema.createdAt],
            latitude: row[LocationSchema.latitude],
            longitude: row[LocationSchema.longitude]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            LocationSchema.id <-- id,
            LocationSchema.text <-- text,
            LocationSchema.createdAt <-- createdAt,
            LocationSchema.latitude <-- latitude,
            LocationSchema.longitude <-- longitude
        ]
    }
    
    func insertOrReplace() throws {
        try DatabaseManager.defaultConnection.run(LocationTable.insert(or: .Replace, toSQL()))
    }
    
}

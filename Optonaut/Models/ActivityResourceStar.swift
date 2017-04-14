//
//  ActivityResourceStar.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper

struct ActivityResourceStar {
    
    var ID: UUID
    var optograph: Optograph
    var causingPerson: Person
    
    static func newInstance() -> ActivityResourceStar {
        return ActivityResourceStar(
            ID: uuid(),
            optograph: Optograph.newInstance(),
            causingPerson: Person.newInstance()
        )
    }
}

extension ActivityResourceStar: Mappable {
    
    init?(map: Map){
        self = ActivityResourceStar.newInstance()
    }
    
    mutating func mapping(map: Map) {
        ID              <- map["id"]
        optograph       <- map["optograph"]
        causingPerson   <- map["causing_person"]
    }
    
}

extension ActivityResourceStar: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return ActivityResourceStarSchema
    }
    
    static func table() -> SQLiteTable {
        return ActivityResourceStarTable
    }
    
    static func fromSQL(_ row: SQLiteRow) -> ActivityResourceStar {
        return ActivityResourceStar(
            ID: row[ActivityResourceStarSchema.ID],
            optograph: Optograph.newInstance(),
            causingPerson: Person.newInstance()
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            ActivityResourceStarSchema.ID <-- ID,
            ActivityResourceStarSchema.optographID <-- optograph.ID,
            ActivityResourceStarSchema.causingPersonID <-- causingPerson.ID,
        ]
    }
    
}

//
//  ActivityResourceFollow.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper

struct ActivityResourceFollow {
    
    var ID: UUID
    var causingPerson: Person
    
    static func newInstance() -> ActivityResourceFollow {
        return ActivityResourceFollow(
            ID: uuid(),
            causingPerson: Person.newInstance()
        )
    }
}

extension ActivityResourceFollow: Mappable {
    
    init?(map: Map){
        self = ActivityResourceFollow.newInstance()
    }
    
    mutating func mapping(map: Map) {
        ID              <- map["id"]
        causingPerson   <- map["causing_person"]
    }
    
}

extension ActivityResourceFollow: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return ActivityResourceFollowSchema
    }
    
    static func table() -> SQLiteTable {
        return ActivityResourceFollowTable
    }
    
    static func fromSQL(_ row: SQLiteRow) -> ActivityResourceFollow {
        return ActivityResourceFollow(
            ID: row[ActivityResourceFollowSchema.ID],
            causingPerson: Person.newInstance()
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            ActivityResourceFollowSchema.ID <-- ID,
            ActivityResourceFollowSchema.causingPersonID <-- causingPerson.ID,
        ]
    }
    
}

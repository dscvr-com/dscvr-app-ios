//
//  ActivityResourceViews.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper

struct ActivityResourceViews {
    
    var ID: UUID
    var optograph: Optograph
    var count: Int
    
    static func newInstance() -> ActivityResourceViews {
        return ActivityResourceViews(
            ID: uuid(),
            optograph: Optograph.newInstance(),
            count: 0
        )
    }
}

extension ActivityResourceViews: Mappable {
    
    init?(_ map: Map){
        self = ActivityResourceViews.newInstance()
    }
    
    mutating func mapping(map: Map) {
        ID              <- map["id"]
        optograph       <- map["optograph"]
        count           <- map["count"]
    }
    
}

extension ActivityResourceViews: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return ActivityResourceViewsSchema
    }
    
    static func table() -> SQLiteTable {
        return ActivityResourceViewsTable
    }
    
    static func fromSQL(row: SQLiteRow) -> ActivityResourceViews {
        return ActivityResourceViews(
            ID: row[ActivityResourceViewsSchema.ID],
            optograph: Optograph.newInstance(),
            count: row[ActivityResourceViewsSchema.count]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            ActivityResourceViewsSchema.ID <-- ID,
            ActivityResourceViewsSchema.optographID <-- optograph.ID,
            ActivityResourceViewsSchema.count <-- count,
        ]
    }
    
}

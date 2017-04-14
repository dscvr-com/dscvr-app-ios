//
//  ActivityResourceStarModel.swift
//  DSCVR
//
//  Created by robert john alkuino on 7/19/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct ActivityResourceStarModel: Mappable {
    var ID: UUID = ""
    var optograph:OptographApiModel?
    var causingPerson:PersonApiModel = PersonApiModel()
    
    init() {}
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        ID              <- map["id"]
        optograph       <- map["optograph"]
        causingPerson   <- map["causing_person"]
    }
}

//extension ActivityResourceStarModel: SQLiteModel {
//    
//    static func schema() -> ModelSchema {
//        return ActivityResourceStarSchema
//    }
//    
//    static func table() -> SQLiteTable {
//        return ActivityResourceStarTable
//    }
//    
//    static func fromSQL(row: SQLiteRow) -> ActivityResourceStarModel {
//        return ActivityResourceStarModel(
//            ID: row[ActivityResourceStarSchema.ID],
//            optograph: row[ActivityResourceStarSchema.optographID],
//            causingPerson: row[ActivityResourceStarSchema.causingPersonID]
//        )
//    }
//    
//    func toSQL() -> [SQLiteSetter] {
//        return [
//            ActivityResourceStarSchema.ID <-- ID,
//            ActivityResourceStarSchema.optographID <-- optograph.ID,
//            ActivityResourceStarSchema.causingPersonID <-- causingPerson.ID,
//        ]
//    }
//    
//}

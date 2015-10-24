//
//  ActivityResourceStarTable.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct ActivityResourceStarSchemaType: ModelSchema {
    let ID = Expression<UUID>("activity_resource_star_id")
    let optographID = Expression<UUID>("activity_resource_star_optograph_id")
    let causingPersonID = Expression<UUID>("activity_resource_star_causing_person_id")
}

let ActivityResourceStarSchema = ActivityResourceStarSchemaType()
let ActivityResourceStarTable = Table("activity_resource_star")

func ActivityResourceStarMigration() -> String {
    return ActivityResourceStarTable.create { t in
        t.column(ActivityResourceStarSchema.ID, primaryKey: true)
        t.column(ActivityResourceStarSchema.optographID)
        t.column(ActivityResourceStarSchema.causingPersonID)
    }
}

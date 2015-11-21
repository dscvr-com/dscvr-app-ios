//
//  ActivityResourceFollowTable.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct ActivityResourceFollowSchemaType: ModelSchema {
    let ID = Expression<UUID>("activity_resource_follow_id")
    let causingPersonID = Expression<UUID>("activity_resource_follow_causing_person_id")
}

let ActivityResourceFollowSchema = ActivityResourceFollowSchemaType()
let ActivityResourceFollowTable = Table("activity_resource_follow")
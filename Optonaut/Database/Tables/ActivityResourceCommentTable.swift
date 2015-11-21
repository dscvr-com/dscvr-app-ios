//
//  ActivityResourceCommentTable.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct ActivityResourceCommentSchemaType: ModelSchema {
    let ID = Expression<UUID>("activity_resource_comment_id")
    let optographID = Expression<UUID>("activity_resource_comment_optograph_id")
    let commentID = Expression<UUID>("activity_resource_comment_comment_id")
    let causingPersonID = Expression<UUID>("activity_resource_comment_causing_person_id")
}

let ActivityResourceCommentSchema = ActivityResourceCommentSchemaType()
let ActivityResourceCommentTable = Table("activity_resource_comment")
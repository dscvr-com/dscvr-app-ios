//
//  StoryTable.swift
//  DSCVR
//
//  Created by robert john alkuino on 10/5/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import SQLite

struct StorySchemaType: ModelSchema {
    let ID = Expression<UUID>("story_id")
    let createdAt = Expression<Date>("story_created_at")
    let updatedAt = Expression<Date>("story_updated_at")
    let deletedAt = Expression<Date?>("story_deleted_at")
    let optographID = Expression<UUID>("story_optographd_id")
    let personID = Expression<UUID>("story_person_id")
    let storyChildrenId = Expression<UUID>("story_children_id")
}

let StorySchema = StorySchemaType()
let StoryTable = Table("story")

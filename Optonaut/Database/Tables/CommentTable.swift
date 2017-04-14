//
//  Comment.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/16/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct CommentSchemaType: ModelSchema {
    let ID = Expression<UUID>("comment_id")
    let text = Expression<String>("comment_text")
    let createdAt = Expression<Date>("comment_created_at")
    let updatedAt = Expression<Date>("comment_updated_at")
    let personID = Expression<UUID>("comment_person_id")
    let optographID = Expression<UUID>("comment_optograph_id")
}

let CommentSchema = CommentSchemaType()
let CommentTable = Table("comment")

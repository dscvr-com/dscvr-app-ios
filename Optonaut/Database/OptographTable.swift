//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct OptographSchemaType: ModelSchema {
    let id = Expression<UUID>("optograph_id")
    let text = Expression<String>("optograph_text")
    let personId = Expression<UUID>("optograph_person_id")
    let locationId = Expression<UUID>("optograph_location_id")
    let createdAt = Expression<NSDate>("optograph_created_at")
    let isStarred = Expression<Bool>("optograph_is_starred")
    let starsCount = Expression<Int>("optograph_stars_count")
    let commentsCount = Expression<Int>("optograph_comments_count")
    let viewsCount = Expression<Int>("optograph_views_count")
    let isPublished = Expression<Bool>("optograph_is_published")
}

let OptographSchema = OptographSchemaType()
let OptographTable = Table("optograph")

func OptographMigration() -> String {
    return OptographTable.create { t in
        t.column(OptographSchema.id, primaryKey: true)
        t.column(OptographSchema.text)
        t.column(OptographSchema.personId)
        t.column(OptographSchema.locationId)
        t.column(OptographSchema.createdAt)
        t.column(OptographSchema.isStarred)
        t.column(OptographSchema.starsCount)
        t.column(OptographSchema.commentsCount)
        t.column(OptographSchema.viewsCount)
        t.column(OptographSchema.isPublished)
    }
}
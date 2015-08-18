//
//  OptographSchema.swift
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
    let createdAt = Expression<NSDate>("optograph_created_at")
    let isStarred = Expression<Bool>("optograph_is_starred")
    let starsCount = Expression<Int>("optograph_stars_count")
    let commentsCount = Expression<Int>("optograph_comments_count")
    let viewsCount = Expression<Int>("optograph_views_count")
    let location = Expression<String>("optograph_location")
}

let OptographSchema = OptographSchemaType()
let OptographTable = Table("optograph")
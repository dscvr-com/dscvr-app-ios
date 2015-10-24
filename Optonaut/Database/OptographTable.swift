//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct OptographSchemaType: ModelSchema {
    let ID = Expression<UUID>("optograph_id")
    let text = Expression<String>("optograph_text")
    let personID = Expression<UUID>("optograph_person_id")
    let locationID = Expression<UUID>("optograph_location_id")
    let createdAt = Expression<NSDate>("optograph_created_at")
    let deletedAt = Expression<NSDate?>("optograph_deleted_at")
    let isStarred = Expression<Bool>("optograph_is_starred")
    let starsCount = Expression<Int>("optograph_stars_count")
    let commentsCount = Expression<Int>("optograph_comments_count")
    let viewsCount = Expression<Int>("optograph_views_count")
    let isStitched = Expression<Bool>("optograph_is_stitched")
    let isPublished = Expression<Bool>("optograph_is_published")
    let previewAssetID = Expression<UUID>("optograph_preview_asset_id")
    let leftTextureAssetID = Expression<UUID>("optograph_left_texture_asset_id")
    let rightTextureAssetID = Expression<UUID>("optograph_right_texture_asset_id")
    let isStaffPick = Expression<Bool>("optograph_is_staff_pick")
    let hashtagString = Expression<String>("optograph_hashtag_string")
}

let OptographSchema = OptographSchemaType()
let OptographTable = Table("optograph")

func OptographMigration() -> String {
    return OptographTable.create { t in
        t.column(OptographSchema.ID, primaryKey: true)
        t.column(OptographSchema.text)
        t.column(OptographSchema.personID)
        t.column(OptographSchema.locationID)
        t.column(OptographSchema.createdAt)
        t.column(OptographSchema.deletedAt)
        t.column(OptographSchema.isStarred)
        t.column(OptographSchema.starsCount)
        t.column(OptographSchema.commentsCount)
        t.column(OptographSchema.viewsCount)
        t.column(OptographSchema.isStitched)
        t.column(OptographSchema.isPublished)
        t.column(OptographSchema.previewAssetID)
        t.column(OptographSchema.leftTextureAssetID)
        t.column(OptographSchema.rightTextureAssetID)
        t.column(OptographSchema.isStaffPick)
        t.column(OptographSchema.hashtagString)
    }
}
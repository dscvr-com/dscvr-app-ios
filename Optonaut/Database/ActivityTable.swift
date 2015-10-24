//  ActivityTable.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct ActivitySchemaType: ModelSchema {
    let ID = Expression<UUID>("activity_id")
    let createdAt = Expression<NSDate>("activity_created_at")
    let deletedAt = Expression<NSDate?>("activity_deleted_at")
    let type = Expression<String>("activity_type")
    let isRead = Expression<Bool>("activity_is_read")
    let activityResourceStarID = Expression<UUID?>("activity_activity_resource_star_id")
    let activityResourceCommentID = Expression<UUID?>("activity_activity_resource_comment_id")
    let activityResourceViewsID = Expression<UUID?>("activity_activity_resource_views_id")
    let activityResourceFollowID = Expression<UUID?>("activity_activity_resource_follow_id")
}

let ActivitySchema = ActivitySchemaType()
let ActivityTable = Table("activity")

func ActivityMigration() -> String {
    return ActivityTable.create { t in
        t.column(ActivitySchema.ID, primaryKey: true)
        t.column(ActivitySchema.createdAt)
        t.column(ActivitySchema.deletedAt)
        t.column(ActivitySchema.type)
        t.column(ActivitySchema.isRead)
        t.column(ActivitySchema.activityResourceStarID)
        t.column(ActivitySchema.activityResourceCommentID)
        t.column(ActivitySchema.activityResourceViewsID)
        t.column(ActivitySchema.activityResourceFollowID)
    }
}
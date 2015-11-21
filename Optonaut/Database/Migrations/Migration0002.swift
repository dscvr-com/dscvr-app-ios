//
//  Migration0002.swift
//  Optonaut
//
//  Created by Johannes Schickling on 20/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

func migration0002(db: Connection) throws {
    try db.run(createActivityResourceComment())
    try db.run(createActivityResourceFollow())
    try db.run(createActivityResourceStar())
    try db.run(createActivityResourceViews())
    try db.run(createActivity())
}

private func createActivityResourceComment() -> String {
    return ActivityResourceCommentTable.create { t in
        t.column(ActivityResourceCommentSchema.ID, primaryKey: true)
        t.column(ActivityResourceCommentSchema.optographID)
        t.column(ActivityResourceCommentSchema.commentID)
        t.column(ActivityResourceCommentSchema.causingPersonID)
        
        t.foreignKey(ActivityResourceCommentSchema.optographID, references: OptographTable, OptographSchema.ID)
        t.foreignKey(ActivityResourceCommentSchema.commentID, references: CommentTable, CommentSchema.ID)
        t.foreignKey(ActivityResourceCommentSchema.causingPersonID, references: PersonTable, PersonSchema.ID)
    }
}

private func createActivityResourceFollow() -> String {
    return ActivityResourceFollowTable.create { t in
        t.column(ActivityResourceFollowSchema.ID, primaryKey: true)
        t.column(ActivityResourceFollowSchema.causingPersonID)
        
        t.foreignKey(ActivityResourceFollowSchema.causingPersonID, references: PersonTable, PersonSchema.ID)
    }
}

private func createActivityResourceStar() -> String {
    return ActivityResourceStarTable.create { t in
        t.column(ActivityResourceStarSchema.ID, primaryKey: true)
        t.column(ActivityResourceStarSchema.optographID)
        t.column(ActivityResourceStarSchema.causingPersonID)
        
        t.foreignKey(ActivityResourceStarSchema.optographID, references: OptographTable, OptographSchema.ID)
        t.foreignKey(ActivityResourceStarSchema.causingPersonID, references: PersonTable, PersonSchema.ID)
    }
}

private func createActivityResourceViews() -> String {
    return ActivityResourceViewsTable.create { t in
        t.column(ActivityResourceViewsSchema.ID, primaryKey: true)
        t.column(ActivityResourceViewsSchema.count)
        t.column(ActivityResourceViewsSchema.optographID)
        
        t.foreignKey(ActivityResourceViewsSchema.optographID, references: OptographTable, OptographSchema.ID)
    }
}

private func createActivity() -> String {
    return ActivityTable.create { t in
        t.column(ActivitySchema.ID, primaryKey: true)
        t.column(ActivitySchema.createdAt)
        t.column(ActivitySchema.deletedAt)
        t.column(ActivitySchema.type)
        t.column(ActivitySchema.isRead)
        t.column(ActivitySchema.activityResourceCommentID)
        t.column(ActivitySchema.activityResourceFollowID)
        t.column(ActivitySchema.activityResourceStarID)
        t.column(ActivitySchema.activityResourceViewsID)
        
        t.foreignKey(ActivitySchema.activityResourceCommentID, references: ActivityResourceCommentTable, ActivityResourceCommentSchema.ID)
        t.foreignKey(ActivitySchema.activityResourceFollowID, references: ActivityResourceFollowTable, ActivityResourceFollowSchema.ID)
        t.foreignKey(ActivitySchema.activityResourceStarID, references: ActivityResourceStarTable, ActivityResourceStarSchema.ID)
        t.foreignKey(ActivitySchema.activityResourceViewsID, references: ActivityResourceViewsTable, ActivityResourceViewsSchema.ID)
    }
}
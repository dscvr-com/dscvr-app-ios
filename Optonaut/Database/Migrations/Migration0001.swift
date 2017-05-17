//
//  Migration0001.swift
//  Optonaut
//
//  Created by Johannes Schickling on 20/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

func migration0001(_ db: Connection) throws {
    try db.run(createOptograph())
}

private func createOptograph() -> String {
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
        t.column(OptographSchema.isStaffPick)
        t.column(OptographSchema.hashtagString)
    }
}

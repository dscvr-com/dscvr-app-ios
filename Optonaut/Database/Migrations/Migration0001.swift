//
//  Migration0001.swift
//  Optonaut
//
//  Created by Johannes Schickling on 20/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

func migration0001(_ db: Connection) throws {
    try db.run(createPerson())
    try db.run(createOptograph())
    try db.run(createGuestPerson())
}

private func createPerson() -> String {
    return PersonTable.create { t in
        t.column(PersonSchema.ID, primaryKey: true)
        t.column(PersonSchema.email)
        t.column(PersonSchema.displayName)
        t.column(PersonSchema.userName)
        t.column(PersonSchema.text)
        t.column(PersonSchema.followersCount)
        t.column(PersonSchema.followedCount)
        t.column(PersonSchema.isFollowed)
        t.column(PersonSchema.createdAt)
        t.column(PersonSchema.avatarAssetID)
    }
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
        
        t.foreignKey(OptographSchema.personID, references: PersonTable, PersonSchema.ID)
    }
}

private func createGuestPerson() -> Insert {
    return PersonTable.insert(or: .fail, [
        PersonSchema.ID <- Person.guestID,
        PersonSchema.displayName <- "Guest",
        PersonSchema.userName <- "guest",
        PersonSchema.text <- "",
        PersonSchema.followersCount <- 0,
        PersonSchema.followedCount <- 0,
        PersonSchema.isFollowed <- false,
        PersonSchema.createdAt <- Date(),
        PersonSchema.avatarAssetID <- uuid(),
    ])
}

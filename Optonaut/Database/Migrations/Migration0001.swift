//
//  Migration0001.swift
//  Optonaut
//
//  Created by Johannes Schickling on 20/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

func migration0001(db: Connection) throws {
    try db.run(createPerson())
    try db.run(createLocation())
    try db.run(createOptograph())
    try db.run(createHashtag())
    try db.run(createComment())
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
//        t.column(PersonSchema.wantsNewsletter) // removed
        t.column(PersonSchema.avatarAssetID)
    }
}

private func createLocation() -> String {
    return LocationTable.create { t in
        t.column(LocationSchema.ID, primaryKey: true)
        t.column(LocationSchema.text)
        t.column(LocationSchema.country)
        t.column(LocationSchema.createdAt)
        t.column(LocationSchema.latitude)
        t.column(LocationSchema.longitude)
    }
}

private func createOptograph() -> String {
    return OptographTable.create { t in
        t.column(OptographSchema.ID, primaryKey: true)
        //t.column(OptographSchema.ID)
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
        t.column(OptographSchema.storyID)
//        t.column(OptographSchema.previewAssetID) // removed
//        t.column(OptographSchema.leftTextureAssetID) // removed
//        t.column(OptographSchema.rightTextureAssetID) // removed
        t.column(OptographSchema.isStaffPick)
        t.column(OptographSchema.hashtagString)
        
        t.foreignKey(OptographSchema.personID, references: PersonTable, PersonSchema.ID)
        t.foreignKey(OptographSchema.storyID, references: StoryTable, StorySchema.ID)
        t.foreignKey(OptographSchema.locationID, references: LocationTable, LocationSchema.ID)
    }
}

private func createHashtag() -> String {
    return HashtagTable.create { t in
        t.column(HashtagSchema.ID, primaryKey: true)
        t.column(HashtagSchema.name)
        t.column(HashtagSchema.previewAssetID)
        t.column(HashtagSchema.isFollowed)
    }
}

private func createComment() -> String {
    return CommentTable.create { t in
        t.column(CommentSchema.ID, primaryKey: true)
        t.column(CommentSchema.text)
        t.column(CommentSchema.createdAt)
        t.column(CommentSchema.personID)
        t.column(CommentSchema.optographID)
        
        t.foreignKey(CommentSchema.optographID, references: OptographTable, OptographSchema.ID)
    }
}

private func createGuestPerson() -> Insert {
    return PersonTable.insert(or: .Fail, [
        PersonSchema.ID <- Person.guestID,
        PersonSchema.displayName <- "Guest",
        PersonSchema.userName <- "guest",
        PersonSchema.text <- "",
        PersonSchema.followersCount <- 0,
        PersonSchema.followedCount <- 0,
        PersonSchema.isFollowed <- false,
        PersonSchema.createdAt <- NSDate(),
//        PersonSchema.wantsNewsletter <- false, // removed
        PersonSchema.avatarAssetID <- uuid(),
    ])
}
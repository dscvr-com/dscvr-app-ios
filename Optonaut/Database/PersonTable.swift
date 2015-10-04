//
//  Person.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/16/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct PersonSchemaType: ModelSchema {
    let id = Expression<UUID>("person_id")
    let email = Expression<String>("person_email")
    let displayName = Expression<String>("person_display_name")
    let userName = Expression<String>("person_user_name")
    let text = Expression<String>("person_text")
    let followersCount = Expression<Int>("person_followers_count")
    let followedCount = Expression<Int>("person_followed_count")
    let isFollowed = Expression<Bool>("person_is_followed")
    let createdAt = Expression<NSDate>("person_created_at")
    let wantsNewsletter = Expression<Bool>("person_wants_newsletter")
    let avatarAssetId = Expression<UUID>("person_avatar_asset_id")
}

let PersonSchema = PersonSchemaType()
let PersonTable = Table("person")

func PersonMigration() -> String {
    return PersonTable.create { t in
        t.column(PersonSchema.id, primaryKey: true)
        t.column(PersonSchema.email)
        t.column(PersonSchema.displayName)
        t.column(PersonSchema.userName)
        t.column(PersonSchema.text)
        t.column(PersonSchema.followersCount)
        t.column(PersonSchema.followedCount)
        t.column(PersonSchema.isFollowed)
        t.column(PersonSchema.createdAt)
        t.column(PersonSchema.wantsNewsletter)
        t.column(PersonSchema.avatarAssetId)
    }
}
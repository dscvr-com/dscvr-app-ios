//
//  PersonSchema.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/16/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct PersonSchemaType: ModelSchema {
    let id = Expression<UUID>("person_id")
    let email = Expression<String>("person_email")
    let fullName = Expression<String>("person_full_name")
    let userName = Expression<String>("person_user_name")
    let text = Expression<String>("person_text")
    let followersCount = Expression<Int>("person_followers_count")
    let followedCount = Expression<Int>("person_followed_count")
    let isFollowed = Expression<Bool>("person_is_followed")
    let createdAt = Expression<NSDate>("person_created_at")
    let wantsNewsletter = Expression<Bool>("person_wants_newsletter")
}

let PersonSchema = PersonSchemaType()
let PersonTable = Table("person")
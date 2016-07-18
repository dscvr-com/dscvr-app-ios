//
//  Person.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/16/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct PersonSchemaType: ModelSchema {
    let ID = Expression<UUID>("person_id")
    let createdAt = Expression<NSDate>("person_created_at")
    let updatedAt = Expression<NSDate>("person_updated_at")
    let email = Expression<String?>("person_email")
    let displayName = Expression<String>("person_display_name")
    let userName = Expression<String>("person_user_name")
    let text = Expression<String>("person_text")
    let optographsCount = Expression<Int>("person_optographs_count")
    let followersCount = Expression<Int>("person_followers_count")
    let followedCount = Expression<Int>("person_followed_count")
    let isFollowed = Expression<Bool>("person_is_followed")
    let avatarAssetID = Expression<UUID>("person_avatar_asset_id")
    let eliteStatus = Expression<Int>("person_elite_status")
}

let PersonSchema = PersonSchemaType()
let PersonTable = Table("person")
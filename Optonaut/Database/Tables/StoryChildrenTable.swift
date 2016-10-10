//
//  StoryChildrenTable.swift
//  DSCVR
//
//  Created by robert john alkuino on 10/5/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import SQLite

struct StoryChildrenSchemaType: ModelSchema {
    let ID = Expression<UUID>("story_children_object_id")
    let storyID = Expression<UUID>("story_children_object_story_id")
    let storyMediaType = Expression<String>("story_children_object_media_type")
    let storyMediaFace = Expression<String>("story_children_object_media_face")
    let storyMediaDescription = Expression<String>("story_children_object_media_description")
    let storyMediaAdditionalData = Expression<String>("story_children_object_media_additional_data")
    let storyPosition = Expression<NSArray?>("story_children_object_position")
    let storyRotation = Expression<NSArray?>("story_children_object_rotation")
    let storyCreatedAt = Expression<NSDate>("story_children_object_created_at")
    let storyUpdatedAt = Expression<NSDate>("story_children_object_updated_at")
    let storyDeletedAt = Expression<NSDate>("story_children_object_deleted_at")
    let storyMediaFilename = Expression<String>("story_children_object_media_filename")
    let storyMediaFileurl = Expression<String>("story_children_object_media_fileurl")
}

let StoryChildrenSchema = StoryChildrenSchemaType()
let StoryChildrenTable = Table("storyChildren")

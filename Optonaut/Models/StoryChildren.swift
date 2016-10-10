//
//  StoryChildren.swift
//  DSCVR
//
//  Created by robert john alkuino on 10/10/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import ObjectMapper
import ReactiveCocoa

struct StoryChildren: Model {
    var ID: UUID
    var createdAt: NSDate
    var updatedAt: NSDate
    var deletedAt: NSDate
    
    var storyID: String = ""
    var mediaType: String = ""
    var mediaFace: String = ""
    var mediaDescription: String = ""
    var mediaAdditionalData: String = ""
    var objectPosition: [String] = []
    var objectRotation: [String] = []
    var objectMediaFilename: String = ""
    var objectMediaFileUrl: String = ""
    
    static func newInstance() -> StoryChildren {
        return StoryChildren(
            ID: uuid(),
            createdAt: NSDate(),
            updatedAt: NSDate(),
            deletedAt: NSDate(),
            storyID: "",
            mediaType: "",
            mediaFace: "" ,
            mediaDescription: "",
            mediaAdditionalData: "",
            objectPosition: [],
            objectRotation: [],
            objectMediaFilename: "",
            objectMediaFileUrl: ""
        )
    }
}


extension StoryChildren: MergeApiModel {
    typealias AM = StorytellingChildren
    
    mutating func mergeApiModel(apiModel: StorytellingChildren) {
        ID = apiModel.ID
        createdAt = apiModel.createdAt
        updatedAt = apiModel.updatedAt
        deletedAt = apiModel.deletedAt
        storyID = apiModel.storyID
        mediaType = apiModel.mediaType
        mediaFace = apiModel.mediaFace
        mediaDescription = apiModel.mediaDescription
        mediaAdditionalData = apiModel.mediaAdditionalData
        objectPosition = apiModel.objectPosition
        objectRotation = apiModel.objectRotation
        objectMediaFilename = apiModel.objectMediaFilename
        objectMediaFileUrl = apiModel.objectMediaFileUrl
    }
}

extension StoryChildren: Equatable {}

func ==(lhs: StoryChildren, rhs: StoryChildren) -> Bool {
    return lhs.ID == rhs.ID
        && lhs.createdAt == rhs.createdAt
        && lhs.updatedAt == rhs.updatedAt
        && lhs.deletedAt == rhs.deletedAt
        && lhs.storyID   == rhs.storyID
        && lhs.mediaType == rhs.mediaType
        && lhs.mediaFace == rhs.mediaFace
        && lhs.mediaDescription == rhs.mediaDescription
        && lhs.mediaAdditionalData == rhs.mediaAdditionalData
        && lhs.objectPosition == rhs.objectPosition
        && lhs.objectRotation == rhs.objectRotation
        && lhs.objectMediaFilename == rhs.objectMediaFilename
        && lhs.objectMediaFileUrl == rhs.objectMediaFileUrl
}

extension StoryChildren: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return StoryChildrenSchema
    }
    
    static func table() -> SQLiteTable {
        return StoryChildrenTable
    }
    
    static func fromSQL(row: SQLiteRow) -> StoryChildren {
        return StoryChildren(
            ID: row[StorySchema.ID],
            createdAt: row[StoryChildrenSchema.storyCreatedAt],
            updatedAt: row[StoryChildrenSchema.storyUpdatedAt],
            deletedAt: row[StoryChildrenSchema.storyDeletedAt],
            storyID: row[StoryChildrenSchema.storyID],
            mediaType: row[StoryChildrenSchema.storyMediaType],
            mediaFace: row[StoryChildrenSchema.storyMediaFace],
            mediaDescription: row[StoryChildrenSchema.storyMediaDescription],
            mediaAdditionalData: row[StoryChildrenSchema.storyMediaAdditionalData],
            objectPosition: row[StoryChildrenSchema.storyPosition],
            objectRotation: row[StoryChildrenSchema.storyRotation],
            objectMediaFilename: row[StoryChildrenSchema.storyMediaFilename],
            objectMediaFileUrl: row[StoryChildrenSchema.storyMediaFileurl]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            StorySchema.ID <-- ID,
            StorySchema.createdAt <-- createdAt,
            StorySchema.updatedAt <-- updatedAt,
            StorySchema.deletedAt <-- updatedAt,
        ]
    }
    
}


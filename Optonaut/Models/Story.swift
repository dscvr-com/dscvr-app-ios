//
//  Story.swift
//  DSCVR
//
//  Created by robert john alkuino on 10/6/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import ObjectMapper
import ReactiveCocoa

struct Story: Model {
    var ID: UUID
    var createdAt: NSDate
    var updatedAt: NSDate
    var deletedAt: NSDate
    var optographID: UUID
    var personID: UUID
    var childrenID: UUID
    
    static func newInstance() -> Story {
        return Story(
            ID: uuid(),
            createdAt: NSDate(),
            updatedAt: NSDate(),
            deletedAt: NSDate(),
            optographID: "",
            personID: "",
            childrenID: ""
        )
    }
}

extension Story: MergeApiModel {
    typealias AM = mapChildren
    
    mutating func mergeApiModel(apiModel: mapChildren) {
        ID = apiModel.ID
        createdAt = apiModel.createdAt
        updatedAt = apiModel.updatedAt
        deletedAt = apiModel.deletedAt
        optographID = apiModel.optographID
        personID = apiModel.personID
    }
}

extension Story: Equatable {}

func ==(lhs: Story, rhs: Story) -> Bool {
    return lhs.ID == rhs.ID
        && lhs.createdAt == rhs.createdAt
        && lhs.updatedAt == rhs.updatedAt
        && lhs.deletedAt == rhs.deletedAt
        && lhs.optographID == rhs.optographID
        && lhs.personID == rhs.personID
        && lhs.childrenID == rhs.childrenID
}

extension Story: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return StorySchema
    }
    
    static func table() -> SQLiteTable {
        return StoryTable
    }
    
    static func fromSQL(row: SQLiteRow) -> Story {
        return Story(
            ID: row[StorySchema.ID],
            createdAt: row[StorySchema.createdAt],
            updatedAt: row[StorySchema.updatedAt],
            deletedAt: row[StorySchema.deletedAt],
            optographID: row[StorySchema.optographID],
            personID: row[StorySchema.personID],
            childrenID: row[StorySchema.storyChildrenId]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            StorySchema.ID <-- ID,
            StorySchema.createdAt <-- createdAt,
            StorySchema.updatedAt <-- updatedAt,
            StorySchema.deletedAt <-- updatedAt,
            StorySchema.optographID <-- optographID,
            StorySchema.personID <-- personID,
            StorySchema.storyChildrenId <-- childrenID,
        ]
    }
    
}

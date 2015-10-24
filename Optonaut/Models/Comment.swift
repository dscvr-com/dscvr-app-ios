//
//  Comment.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct Comment: Model {
    var ID: UUID
    var text: String
    var createdAt: NSDate
    var person: Person
    var optograph: Optograph
    
    static func newInstance() -> Comment {
        return Comment(
            ID:  uuid(),
            text: "",
            createdAt: NSDate(),
            person: Person.newInstance(),
            optograph: Optograph.newInstance()
        )
    }
    
}

extension Comment: Mappable {
    
    init?(_ map: Map){
        self = Comment.newInstance()
    }
    
    mutating func mapping(map: Map) {
        ID          <- map["id"]
        text        <- map["text"]
        person      <- map["person"]
        optograph   <- map["optograph"]
        createdAt   <- (map["created_at"], NSDateTransform())
    }
    
}

extension Comment: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return CommentSchema
    }
    
    static func table() -> SQLiteTable {
        return CommentTable
    }
    
    static func fromSQL(row: SQLiteRow) -> Comment {
        return Comment(
            ID: row[CommentSchema.ID],
            text: row[CommentSchema.text],
            createdAt: row[CommentSchema.createdAt],
            person: Person.newInstance(),
            optograph: Optograph.newInstance()
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            CommentSchema.ID <-- ID,
            CommentSchema.text <-- text,
            CommentSchema.createdAt <-- createdAt,
            CommentSchema.personID <-- person.ID,
            CommentSchema.optographID <-- optograph.ID,
        ]
    }
    
}
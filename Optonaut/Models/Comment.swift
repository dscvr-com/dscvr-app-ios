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
    var id: UUID
    var text: String
    var createdAt: NSDate
    var person: Person
    var optograph: Optograph
}

extension Comment: Mappable {
    
    static func newInstance() -> Mappable {
        return Comment(
            id: uuid(),
            text: "",
            createdAt: NSDate(),
            person: Person.newInstance() as! Person,
            optograph: Optograph.newInstance() as! Optograph
        )
    }
    
    mutating func mapping(map: Map) {
        id          <- map["id"]
        text        <- map["text"]
        person      <- map["person"]
        optograph   <- map["optograph"]
        createdAt   <- (map["created_at"], NSDateTransform())
    }
    
}

extension Comment: SQLiteModel {
    
    static func fromSQL(row: SQLiteRow) -> Comment {
        return Comment(
            id: row[CommentSchema.id],
            text: row[CommentSchema.text],
            createdAt: row[CommentSchema.createdAt],
            person: Person.newInstance() as! Person,
            optograph: Optograph.newInstance() as! Optograph
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            CommentSchema.id <-- id,
            CommentSchema.text <-- text,
            CommentSchema.createdAt <-- createdAt,
            CommentSchema.personId <-- person.id,
            CommentSchema.optographId <-- optograph.id,
        ]
    }
    
    func insertOrReplace() throws {
        try DatabaseManager.defaultConnection.run(CommentTable.insert(or: .Replace, toSQL()))
    }
    
}
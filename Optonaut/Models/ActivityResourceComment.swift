//
//  ActivityResourceComment.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper

struct ActivityResourceComment {
    
    var ID: UUID
    var optograph: Optograph
    var comment: Comment
    var causingPerson: Person
    
    static func newInstance() -> ActivityResourceComment {
        return ActivityResourceComment(
            ID: uuid(),
            optograph: Optograph.newInstance(),
            comment: Comment.newInstance(),
            causingPerson: Person.newInstance()
        )
    }
}

extension ActivityResourceComment: Mappable {
    
    init?(_ map: Map){
        self = ActivityResourceComment.newInstance()
    }
    
    mutating func mapping(map: Map) {
        ID              <- map["id"]
        optograph       <- map["optograph"]
        comment         <- map["comment"]
        causingPerson   <- map["causing_person"]
    }
    
}

extension ActivityResourceComment: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return ActivityResourceCommentSchema
    }
    
    static func table() -> SQLiteTable {
        return ActivityResourceCommentTable
    }
    
    static func fromSQL(row: SQLiteRow) -> ActivityResourceComment {
        return ActivityResourceComment(
            ID: row[ActivityResourceCommentSchema.ID],
            optograph: Optograph.newInstance(),
            comment: Comment.newInstance(),
            causingPerson: Person.newInstance()
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            ActivityResourceCommentSchema.ID <-- ID,
            ActivityResourceCommentSchema.optographID <-- optograph.ID,
            ActivityResourceCommentSchema.commentID <-- comment.ID,
            ActivityResourceCommentSchema.causingPersonID <-- causingPerson.ID,
        ]
    }
    
}

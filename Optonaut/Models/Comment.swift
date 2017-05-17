//
//  Comment.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

//import Foundation
//import ObjectMapper
//
//struct Comment: Model {
//    var ID: UUID
//    var createdAt: Date
//    var updatedAt: Date
//    var text: String
//    var person: PersonApiModel?
//    var optograph: Optograph
//    
//    static func newInstance() -> Comment {
//        return Comment(
//            ID:  uuid(),
//            createdAt: Date(),
//            updatedAt: Date(),
//            text: "",
//            person: PersonApiModel(),
//            optograph: Optograph.newInstance()
//        )
//    }
//    
//}
//
//extension Comment: Mappable {
//    
//    init?(map: Map){
//        self = Comment.newInstance()
//    }
//    
//    mutating func mapping(map: Map) {
//        ID          <- map["id"]
//        createdAt   <- (map["created_at"], NSDateTransform())
//        updatedAt   <- (map["updated_at"], NSDateTransform())
//        text        <- map["text"]
//        person      <- map["person"]
//        optograph   <- map["optograph"]
//    }
//    
//}

//extension Comment: SQLiteModel {
//    
//    static func schema() -> ModelSchema {
//        return CommentSchema
//    }
//    
//    static func table() -> SQLiteTable {
//        return CommentTable
//    }
//    
//    static func fromSQL(_ row: SQLiteRow) -> Comment {
//        return Comment(
//            ID: row[CommentSchema.ID],
//            createdAt: row[CommentSchema.createdAt],
//            updatedAt: row[CommentSchema.updatedAt],
//            text: row[CommentSchema.text],
//            person: PersonApiModel(),
//            optograph: Optograph.newInstance()
//        )
//    }
//    
//    func toSQL() -> [SQLiteSetter] {
//        return [
//            CommentSchema.ID <-- ID,
//            CommentSchema.createdAt <-- createdAt,
//            CommentSchema.updatedAt <-- updatedAt,
//            CommentSchema.text <-- text,
//            CommentSchema.personID <-- (person?.ID)!,
//            CommentSchema.optographID <-- optograph.ID,
//        ]
//    }
//    
//}

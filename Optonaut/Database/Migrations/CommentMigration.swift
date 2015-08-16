//
//  CommentMigration.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/16/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

class CommentMigration: Migration {
    
    static func up() -> String {
        return CommentTable.create { t in
            t.column(CommentSchema.id, primaryKey: true)
            t.column(CommentSchema.text)
            t.column(CommentSchema.createdAt)
            t.column(CommentSchema.personId)
            t.column(CommentSchema.optographId)
        }
    }
    
    static func down() -> String {
        return CommentTable.drop()
    }
    
}
//
//  0002-OptographMigration.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

class OptographMigration: Migration {
    
    static func up() -> String {
        return OptographTable.create { t in
            t.column(OptographSchema.id, primaryKey: true)
            t.column(OptographSchema.text)
            t.column(OptographSchema.personId)
            t.column(OptographSchema.createdAt)
            t.column(OptographSchema.isStarred)
            t.column(OptographSchema.starsCount)
            t.column(OptographSchema.commentsCount)
            t.column(OptographSchema.viewsCount)
            t.column(OptographSchema.location)
        }
    }
    
    static func down() -> String {
        return OptographTable.drop()
    }
    
}
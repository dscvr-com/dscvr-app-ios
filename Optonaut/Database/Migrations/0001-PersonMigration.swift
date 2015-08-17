//
//  PersonMigration.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/16/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

class PersonMigration: Migration {
    
    static func up() -> String {
        return PersonTable.create { t in
            t.column(PersonSchema.id, primaryKey: true)
            t.column(PersonSchema.email)
            t.column(PersonSchema.fullName)
            t.column(PersonSchema.userName)
            t.column(PersonSchema.text)
            t.column(PersonSchema.followersCount)
            t.column(PersonSchema.followedCount)
            t.column(PersonSchema.isFollowed)
            t.column(PersonSchema.createdAt)
            t.column(PersonSchema.wantsNewsletter)
        }
    }
    
    static func down() -> String {
        return PersonTable.drop()
    }
    
}
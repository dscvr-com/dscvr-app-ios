//
//  CoreData.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/15/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SQLite

protocol ModelSchema {
    var id: Expression<Int> { get }
}

protocol Migration {
    static func up() -> String
    static func down() -> String
}

extension NSDate {
    class func fromDatatypeValue(stringValue: String) -> NSDate {
        return SQLDateFormatter.dateFromString(stringValue)!
    }
    var datatypeValue: String {
        return SQLDateFormatter.stringFromDate(self)
    }
}



let SQLDateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
    return formatter
    }()



class DatabaseManager {
    
    static var defaultConnection: Connection!
    
    static func prepare() {
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let db = try! Connection("\(path)/db.sqlite3")
        
        // enable console logging
        db.trace(print)
        
        let migrations = Table("schema_migrations")
        let version = Expression<Int>("version")
        
        try! db.run(migrations.create(ifNotExists: true) { t in
            t.column(version, primaryKey: .Autoincrement)
            })
        
        let migrationClasses: [Migration.Type] = [
            PersonMigration.self,
            OptographMigration.self,
            CommentMigration.self
        ]
        
        var currentVersion = db.prepare(migrations).map({ $0[version] }).maxElement() ?? 0
        for migration in migrationClasses.slice(currentVersion) {
            try! db.run(migration.up())
            currentVersion++
            try! db.run(migrations.insert(version <- currentVersion))
        }
        
        defaultConnection = db
    }
    
}
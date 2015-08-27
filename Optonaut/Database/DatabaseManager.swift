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
    var id: Expression<UUID> { get }
}

protocol SQLiteModel {
    static func fromSQL(row: Row) -> Self
    func toSQL() -> [Setter]
}

extension NSDate {
    class func fromDatatypeValue(stringValue: String) -> NSDate {
        return NSDate.fromRFC3339String(stringValue)!
    }
    var datatypeValue: String {
        return self.toRFC3339String()
    }
}

class DatabaseManager {
    
    static var defaultConnection: Connection!
    
    private static let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! + "/db.sqlite3"
    private static let migrations = [
        CommentMigration,
        LocationMigration,
        OptographMigration,
        PersonMigration,
    ]
    private static let tables = [
        CommentTable,
        LocationTable,
        OptographTable,
        PersonTable,
    ]
    
    static func prepare() throws {
        // set database connection instance
        defaultConnection = try Connection(path)
        
        // enable console logging
        //defaultConnection.trace(print)
        
        let lastVersion = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.LastReleaseVersion.rawValue) as? String ?? ""
        let newVersion = NSBundle.mainBundle().releaseVersionNumber
        let isNewVersion = lastVersion != newVersion
        
        // reset database if new version available
        if isNewVersion {
            try reset()
        }
    }
    
    static func reset() throws {
        try dropAllTables()
        try migrate()
    }
    
    private static func dropAllTables() throws {
        for table in tables {
            try defaultConnection.run(table.drop(ifExists: true))
        }
    }
    
    private static func migrate() throws {
        for migration in migrations {
            try defaultConnection.run(migration())
        }
    }
    
}
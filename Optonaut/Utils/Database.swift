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
    
    private static let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! + "/db.sqlite3"
    private static let migrations: [Migration.Type] = [
        PersonMigration.self,
        OptographMigration.self,
        CommentMigration.self,
    ]
    
    static func prepare() throws {
        let lastVersion = NSUserDefaults.standardUserDefaults().objectForKey(PersonDefaultsKeys.LastReleaseVersion.rawValue) as? String ?? ""
        let newVersion = NSBundle.mainBundle().releaseVersionNumber
        let isNewVersion = lastVersion != newVersion
        
        // remove old database if new version
        if isNewVersion {
            try removeDatabaseFile()
        }
        
        let db = try Connection(path)
        
        // enable console logging
        db.trace(print)
        
        // migrate database if new version
        if isNewVersion {
            for migration in migrations {
                try db.run(migration.up())
            }
        }
        
        defaultConnection = db
    }
    
    static func reset() throws {
        try removeDatabaseFile()
        try prepare()
    }
    
    private static func removeDatabaseFile() throws {
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            try NSFileManager.defaultManager().removeItemAtPath(path)
        }
    }
    
}
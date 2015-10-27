//
//  DatabaseService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/15/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SQLite
import ReactiveCocoa

protocol ModelSchema {
    var ID: Expression<UUID> { get }
}

protocol SQLiteModel {
    var ID: UUID { get set }
    static func fromSQL(row: SQLiteRow) -> Self
    static func table() -> SQLiteTable
    static func schema() -> ModelSchema
    func toSQL() -> [Setter]
    func insertOrUpdate() throws
}

extension SQLiteModel {
    
    func insertOrUpdate() throws {
        let setters = toSQL()
        let table = Self.table()
        do {
            try DatabaseService.defaultConnection.run(table.insert(or: .Fail, setters))
        } catch {
            let rowsChanged = try DatabaseService.defaultConnection.run(table.filter(table[Self.schema().ID] ==- ID).update(setters))
            if rowsChanged != 1 {
                throw DatabaseQueryError.NotFound
            }
        }
    }
    
    func insertOrIgnore() {
        let setters = toSQL()
        let table = Self.table()
        do {
            try DatabaseService.defaultConnection.run(table.insert(or: .Fail, setters))
        } catch {}
    }
    
}

extension NSDate {
    class var declaredDatatype: String {
        return String.declaredDatatype
    }
    class func fromDatatypeValue(stringValue: String) -> NSDate {
        return NSDate.fromRFC3339String(stringValue)!
    }
    var datatypeValue: String {
        return toRFC3339String()
    }
}

enum DatabaseQueryType {
    case One
    case Many
}

enum DatabaseQueryError: ErrorType {
    case NotFound
    case Nil
}

class DatabaseService {
    
    static var defaultConnection: Connection!
    
    private static let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! + "/db.sqlite3"
    private static let migrations = [
        ActivityMigration,
        ActivityResourceStarMigration,
        ActivityResourceCommentMigration,
        ActivityResourceViewsMigration,
        ActivityResourceFollowMigration,
        CommentMigration,
        HashtagMigration,
        LocationMigration,
        OptographMigration,
        PersonMigration,
    ]
    private static let tables = [
        ActivityTable,
        ActivityResourceStarTable,
        ActivityResourceCommentTable,
        ActivityResourceViewsTable,
        ActivityResourceFollowTable,
        CommentTable,
        HashtagTable,
        LocationTable,
        OptographTable,
        PersonTable,
    ]
    
    static func prepare() throws {
        // set database connection instance
        defaultConnection = try Connection(path)
        
        // enable console logging
//        defaultConnection.trace { msg in print("\(msg)\n") }
        
        // reset database if new version available
        if VersionService.isNew {
            try reset()
        }
        
        SessionService.onLogout(performAlways: true) { try! reset() }
    }
    
    static func reset() throws {
        try dropAllTables()
        try migrate()
    }
    
    static func query(type: DatabaseQueryType, query: Table) -> SignalProducer<Row, DatabaseQueryError> {
        return SignalProducer { sink, disposable in
            switch type {
            case .One:
                guard let row = DatabaseService.defaultConnection.pluck(query) else {
                    sink.sendError(.NotFound)
                    break
                }
                sink.sendNext(row)
            case .Many:
                for row in DatabaseService.defaultConnection.prepare(query) {
                    sink.sendNext(row)
                }
            }
            
            sink.sendCompleted()
        }
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

typealias SQLiteRow = SQLite.Row
typealias SQLiteTable = SQLite.Table
typealias SQLiteSetter = SQLite.Setter

infix operator <-- {
    associativity left
    precedence 135
    assignment
}

public func <--<V : Value>(column: Expression<V>, value: Expression<V>) -> Setter {
    return column <- value
}
public func <--<V : Value>(column: Expression<V>, value: V) -> Setter {
    return column <- value
}
public func <--<V : Value>(column: Expression<V?>, value: Expression<V>) -> Setter {
    return column <- value
}
public func <--<V : Value>(column: Expression<V?>, value: Expression<V?>) -> Setter {
    return column <- value
}
public func <--<V : Value>(column: Expression<V?>, value: V?) -> Setter {
    return column <- value
}


infix operator ==- {
    associativity left
    precedence 135
}

public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V>, rhs: Expression<V>) -> Expression<Bool> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V>, rhs: Expression<V?>) -> Expression<Bool?> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V?>, rhs: Expression<V>) -> Expression<Bool?> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V?>, rhs: Expression<V?>) -> Expression<Bool?> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V>, rhs: V) -> Expression<Bool> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: Expression<V?>, rhs: V?) -> Expression<Bool?> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: V, rhs: Expression<V>) -> Expression<Bool> {
    return lhs == rhs
}
public func ==-<V : Value where V.Datatype : Equatable>(lhs: V?, rhs: Expression<V?>) -> Expression<Bool?> {
    return lhs == rhs
}
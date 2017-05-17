//
//  DatabaseService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/15/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SQLite
import ReactiveSwift

protocol ModelSchema {
    var ID: Expression<UUID> { get }
}

protocol SQLiteModel {
    var ID: UUID { get set }
    static func fromSQL(_ row: SQLiteRow) -> Self
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
            try DatabaseService.defaultConnection.run(table.insert(or: .fail, setters))
        } catch {
            let rowsChanged = try DatabaseService.defaultConnection.run(table.filter(table[Self.schema().ID] ==- ID).update(setters))
            if rowsChanged != 1 {
                throw DatabaseQueryError.notFound
            }
        }
    }
    
    func insertOrIgnore() {
        let setters = toSQL()
        let table = Self.table()
        do {
            try DatabaseService.defaultConnection.run(table.insert(or: .fail, setters))
        } catch {}
    }
    
}

extension Date {
    static var declaredDatatype: String {
        return String.declaredDatatype
    }
    static func fromDatatypeValue(_ stringValue: String) -> Date {
        return Date.fromRFC3339String(stringValue)!
    }
    var datatypeValue: String {
        return toRFC3339String()
    }
}

enum DatabaseQueryType {
    case one
    case many
}

enum DatabaseQueryError: Error {
    case notFound
    case `nil`
}

class DatabaseService {
    
    static var defaultConnection: Connection!
    
    fileprivate static let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/database.sqlite3"
    fileprivate static let migrations = [
        migration0001,
        migration0002,
        migration0003,
        migration0004,
        migration0005,
        migration0006,
        migration0007,
    ]
    
    static func prepare() throws {
        // set database connection instance
        defaultConnection = try Connection(path)
        try migrate()
    }
    
    static func reset() throws {
        let ephemeralTables = [
            ActivityTable,
            ActivityResourceStarTable,
            ActivityResourceCommentTable,
            ActivityResourceViewsTable,
            ActivityResourceFollowTable,
        ]
        for ephemeralTable in ephemeralTables {
            try defaultConnection.run(ephemeralTable.delete())
        }
        
        let optographsToDelete = OptographTable.filter(OptographSchema.personID != Person.guestID)
        try defaultConnection.run(optographsToDelete.delete())
        
        let personsToDelete = PersonTable.filter(PersonSchema.ID != Person.guestID)
        try defaultConnection.run(personsToDelete.delete())
    }
    
    static func query(_ type: DatabaseQueryType, query: Table) -> SignalProducer<Row, DatabaseQueryError> {
        return SignalProducer { sink, disposable in
            switch type {
            case .one:
                guard let row = try! DatabaseService.defaultConnection.pluck(query) else {
                    sink.send(error: .notFound)
                    break
                }
                sink.send(value: row)
            case .many:
                for row in try! DatabaseService.defaultConnection.prepare(query) {
                    sink.send(value: row)
                }
            }
            
            sink.sendCompleted()
        }
    }
    
    fileprivate static func migrate() throws {
        var userVersion = defaultConnection.userVersion
        for (index, migration) in migrations.enumerated() {
            let migrationVersion = index + 1
            if userVersion < migrationVersion {
                try defaultConnection.transaction {
                    try migration(defaultConnection)
                    defaultConnection.userVersion = migrationVersion
                }
                userVersion = migrationVersion
                print("Migrated database to version \(migrationVersion)")
            }
        }
    }
    
}

typealias SQLiteRow = SQLite.Row
typealias SQLiteTable = SQLite.Table
typealias SQLiteSetter = SQLite.Setter
typealias SQLiteValue = SQLite.Value

extension Connection {
    public var userVersion: Int {
        get { return try! Int(scalar("PRAGMA user_version") as! Int64) }
        set { try! run("PRAGMA user_version = \(newValue)") }
    }
}

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

//
//  SQLiteWrapper.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/27/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SQLite

typealias SQLiteRow = SQLite.Row
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
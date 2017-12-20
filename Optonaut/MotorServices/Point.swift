//
//  Point.swift
//  Orbit 360 Facetracking
//
//  Created by Emi on 17/02/2017.
//  Copyright © 2017 Philipp Meyer. All rights reserved.
//

import Foundation

protocol SummableMultipliableFloat {
    func +(lhs: Self, rhs: Self) -> Self
    func *(lhs: Self, rhs: Float) -> Self
}

struct Point: SummableMultipliableFloat {
    let x: Float
    let y: Float
    
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

extension Point {
static func +(a: Point, b: Point) -> Point {
    return Point(x: a.x + b.x, y: a.y + b.y)
}

static func -(a: Point, b: Point) -> Point {
    return Point(x: a.x - b.x, y: a.y - b.y)
}

static prefix func -(a: Point) -> Point {
    return Point(x: -a.x, y: -a.y)
}

static func *(a: Point, b: Float) -> Point {
    return Point(x: a.x * b, y: a.y * b)
}

static func *(b: Float, a: Point) -> Point {
    return Point(x: a.x * b, y: a.y * b)
}

static func /(a: Point, b: Float) -> Point {
    return Point(x: a.x / b, y: a.y / b)
}

static func /(b: Float, a: Point) -> Point {
    return Point(x: a.x / b, y: a.y / b)
}
}

func pabs(p: Point) -> Point {
    return Point(x: abs(p.x), y: abs(p.y))
}

func pmin(a: Point, b: Point) -> Point {
    return Point(x: min(a.x, b.x), y: min(a.y, b.y))
}

func pmax(a: Point, b: Point) -> Point {
    return Point(x: max(a.x, b.x), y: max(a.y, b.y))
}

func psign(a: Point) -> Point {
    return Point(x: sign(a.x), y: sign(a.y))
}

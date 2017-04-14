//
//  Debug.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/9/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

func logRetain() {
    let caller = Thread.callStackSymbols[1]
    let results = caller.components(separatedBy: CharacterSet(charactersIn: " -[]+?.,")).filter(isNotEmpty)
    print("Deinit \(results[3])")
}

func logInit() {
    let caller = Thread.callStackSymbols[1]
    let results = caller.components(separatedBy: CharacterSet(charactersIn: " -[]+?.,")).filter(isNotEmpty)
    print("Init \(results[3])")
}

func assertMainThread() {
    assert(Thread.current.isMainThread, "has to be called on main thread")
}

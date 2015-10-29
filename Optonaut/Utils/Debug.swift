//
//  Debug.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/9/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

func logRetain() {
    let caller = NSThread.callStackSymbols()[1]
    let results = caller.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: " -[]+?.,")).filter(isNotEmpty)
    print("Deinit \(results[3])")
}
func logInit() {
    let caller = NSThread.callStackSymbols()[1]
    let results = caller.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: " -[]+?.,")).filter(isNotEmpty)
    print("Init \(results[3])")
}
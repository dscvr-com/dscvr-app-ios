//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import RealmSwift

class Optograph: Object {
    dynamic var id = 0
    dynamic var text = ""
    dynamic var numberOfLikes = 0
    dynamic var user: User?
    dynamic var createdAt = NSDate()
    dynamic var likedByUser = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
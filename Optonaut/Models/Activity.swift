//
//  Activity.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/27/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import RealmSwift

enum ActivityType: String {
    case Like = "like"
    case Follow = "follow"
    case Nil = ""
}

class Activity: Object {
    dynamic var id = 0
    dynamic var creator: User?
    dynamic var optograph: Optograph?
    dynamic var createdAt = NSDate()
    var activityType: ActivityType = .Nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
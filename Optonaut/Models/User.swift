//
//  User.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import RealmSwift

class User: Object {
    dynamic var id = 0
    dynamic var email = ""
    dynamic var userName = ""
    dynamic var numberOfFollowers = 0
    dynamic var numberOfFollowings = 0
    dynamic var numberOfOptographs = 0
    dynamic var isFollowing = false
    
    let optographs = List<Optograph>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
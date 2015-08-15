//
//  Comment.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class Comment: Object, Model {
    dynamic var id = 0
    dynamic var text = ""
    dynamic var createdAt = NSDate()
    dynamic var person: Person?
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

func ==(lhs: Comment, rhs: Comment) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension Comment: Mappable {
    
    func mapping(map: Map) {
        id                  <- map["id"]
        text                <- map["text"]
        person              <- map["person"]
        createdAt           <- (map["created_at"], NSDateTransform())
    }
    
    static func newInstance() -> Mappable {
        return Comment()
    }
    
}

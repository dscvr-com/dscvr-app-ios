//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class Optograph: Object, Model {
    dynamic var id = 0
    dynamic var text = ""
    dynamic var person: Person?
    dynamic var createdAt = NSDate()
    dynamic var isStarred = false
    dynamic var starsCount = 0
    dynamic var commentsCount = 0
    dynamic var viewsCount = 0
    dynamic var location = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

func ==(lhs: Optograph, rhs: Optograph) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension Optograph: Mappable {
    
    static func newInstance() -> Mappable {
        return Optograph()
    }
    
    func mapping(map: Map) {
        id              <- map["id"]
        text            <- map["text"]
        person          <- map["person"]
        createdAt       <- (map["created_at"], NSDateTransform())
        isStarred       <- map["is_starred"]
        starsCount      <- map["stars_count"]
        commentsCount   <- map["comments_count"]
        viewsCount      <- map["views_count"]
        location        <- map["location.text"]
    }
    
}
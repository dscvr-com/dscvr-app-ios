//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct Optograph: Model {
    var id: UUID
    var text: String
    var person: Person?
    var createdAt: NSDate
    var isStarred: Bool
    var starsCount: Int
    var commentsCount: Int
    var viewsCount: Int
    var location: String
}

extension Optograph: Mappable {
    
    static func newInstance() -> Mappable {
        return Optograph(
            id: uuid(),
            text: "",
            person: nil,
            createdAt: NSDate(),
            isStarred: false,
            starsCount: 0,
            commentsCount: 0,
            viewsCount: 0,
            location: ""
        )
    }
    
    mutating func mapping(map: Map) {
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
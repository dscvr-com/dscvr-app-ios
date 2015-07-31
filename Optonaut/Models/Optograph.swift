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

class Optograph: Object {
    dynamic var id = 0
    dynamic var text = ""
    dynamic var user: User?
    dynamic var createdAt = NSDate()
    dynamic var likedByUser = false
    dynamic var likeCount = 0
    dynamic var commentCount = 0
    dynamic var viewsCount = 0
    dynamic var location = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

extension Optograph: Mappable {
    
    static func newInstance() -> Mappable {
        return Optograph()
    }
    
    func mapping(map: Map) {
        id              <- map["id"]
        text            <- map["text"]
        user            <- map["user"]
        createdAt       <- (map["created_at"], NSDateTransform())
        likedByUser     <- map["liked_by_user"]
        likeCount       <- map["like_count"]
        commentCount    <- map["comment_count"]
        viewsCount      <- map["views_count"]
        location        <- map["location.description"]
    }
    
}

// needed to merge two arrays via a Set
extension Optograph: Hashable {
    override var hashValue: Int {
        get {
            return id.hashValue
        }
    }
}
func ==(lhs: Optograph, rhs: Optograph) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

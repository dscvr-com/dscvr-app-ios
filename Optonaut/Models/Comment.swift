//
//  Comment.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct Comment: Model {
    var id: UUID
    var text: String
    var createdAt: NSDate
    var person: Person?
    var optograph: Optograph?
}

extension Comment: Mappable {
    
    static func newInstance() -> Mappable {
        return Comment(
            id: uuid(),
            text: "",
            createdAt: NSDate(),
            person: nil,
            optograph: nil
        )
    }
    
    mutating func mapping(map: Map) {
        id          <- map["id"]
        text        <- map["text"]
        person      <- map["person"]
        optograph   <- map["optograph"]
        createdAt   <- (map["created_at"], NSDateTransform())
    }
    
}

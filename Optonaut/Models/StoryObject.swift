//
//  StoryObject.swift
//  DSCVR
//
//  Created by Thadz on 03/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct StoryObject: Mappable {
    var status: String = ""
    var message:  String = ""
    var children:[mapChildren]?
    
    init?(_ map: Map) {}
    
    subscript(index: Int) -> mapChildren? {
        guard let coordinate = children?[0] else {
            return nil
        }
        return coordinate
    }
    
    mutating func mapping(map: Map) {
        status              <- map["status"]
        message                 <- map["message"]
        children <- map["data"]
    }
}
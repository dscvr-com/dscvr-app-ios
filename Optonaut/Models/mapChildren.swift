//
//  mapChildren.swift
//  DSCVR
//
//  Created by robert john alkuino on 8/5/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct mapChildren: Mappable {
    var children:[StorytellingChildren]?
    
    init?(_ map: Map) {
    }
    
    mutating func mapping(map: Map) {
        children              <- map["children"]
    }
}
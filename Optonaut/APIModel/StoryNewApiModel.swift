//
//  StoryNewApiModel.swift
//  DSCVR
//
//  Created by robert john alkuino on 10/7/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct StoryNewApiModel: Mappable {
    
    var feed:[OptographApiModel]?
    var you:[OptographApiModel]?
    
    init?(_ map: Map){}
    
    mutating func mapping(map: Map) {
        feed                 <- map["feed"]
        you                  <- map["you"]
        
    }
}

//
//  OptographApiModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 22/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct OptographApiModel: ApiModel, Mappable {
    
    var placeholder: String = ""
    var ID: UUID = ""
    var text: String = ""
    var person: PersonApiModel = PersonApiModel()
    var createdAt: NSDate = NSDate()
    var updatedAt: NSDate = NSDate()
    var deletedAt: NSDate? = nil
    var isStarred: Bool = false
    var isPrivate: Bool = false
    var starsCount: Int = 0
    var commentsCount: Int = 0
    var viewsCount: Int = 0
    var location: LocationApiModel?
    var stitcherVersion: String = ""
    var shareAlias: String = ""
    var isStaffPick: Bool = false
    var directionPhi: Double = 0
    var directionTheta: Double = 0
    var story: mapChildren = mapChildren()
    
    init?(_ map: Map){
    }
    
    mutating func mapping(map: Map) {
        
        placeholder                 <- map["placeholder"]
        ID                          <- map["id"]
        createdAt                   <- (map["created_at"], NSDateTransform())
        updatedAt                   <- (map["updated_at"], NSDateTransform())
        deletedAt                   <- (map["deleted_at"], NSDateTransform())
        text                        <- map["text"]
        person                      <- map["person"]
        isStarred                   <- map["is_starred"]
        isPrivate                   <- map["is_private"]
        stitcherVersion             <- map["stitcher_version"]
        shareAlias                  <- map["share_alias"]
        starsCount                  <- map["stars_count"]
        commentsCount               <- map["comments_count"]
        viewsCount                  <- map["views_count"]
        location                    <- map["location"]
        isStaffPick                 <- map["is_staff_pick"]
        directionPhi                <- map["direction_phi"]
        directionTheta              <- map["direction_theta"]
        story                       <- map["story"]
    }
}
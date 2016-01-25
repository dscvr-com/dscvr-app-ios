//
//  LoginApiModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 23/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct LoginApiModel: Mappable {
    var token: String = ""
    var ID:  UUID = ""
    var onboardingVersion: Int = 0
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        token              <- map["token"]
        ID                 <- map["id"]
        onboardingVersion  <- map["onboarding_version"]
    }
}
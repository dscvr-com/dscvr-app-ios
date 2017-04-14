//
//  MotorConfigurationApiModel.swift
//  DSCVR
//
//  Created by robert john alkuino on 11/28/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct MotorConfigurationApiModel: ApiModel, Mappable {
    
    var ID:UUID = ""
    var createdAt:Date = Date()
    var updatedAt:Date = Date()
    var deletedAt:Date? = nil
    var motor_configuration_pulse_per_second = ""
    var motor_configuration_buff_count = ""
    var motor_configuration_rotate_count = ""
    var motor_configuration_top_count = ""
    var motor_configuration_bot_count = ""
    var motor_configuration_mobile_platform = ""
    
    init() {}
    init?(map: Map) {
    }
    
    mutating func mapping(map: Map) {
        
        ID              <- map["motor_configuration_id"]
        createdAt       <- (map["motor_configuration_created_at"], NSDateTransform())
        updatedAt       <- (map["motor_configuration_updated_at"], NSDateTransform())
        updatedAt       <- (map["motor_configuration_deleted_at"], NSDateTransform())
        
        motor_configuration_pulse_per_second  <-  map["motor_configuration_pulse_per_second"]
        motor_configuration_buff_count        <-  map["motor_configuration_buff_count"]
        motor_configuration_rotate_count      <-  map["motor_configuration_rotate_count"]
        motor_configuration_top_count         <-  map["motor_configuration_top_count"]
        motor_configuration_bot_count         <-  map["motor_configuration_bot_count"]
        motor_configuration_mobile_platform   <-  map["motor_configuration_mobile_platform"]
    }
}

//ahmm just fyi: The current branch which already have stitcher-rewrite,storytelling and motor implementation is both stitcher-rewrite-motorcontrol :)

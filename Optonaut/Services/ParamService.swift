//
//  ParamService.swift
//  DSCVR
//
//  Created by Emanuel Jöbstl on 30/06/2017.
//  Copyright © 2017 Optonaut. All rights reserved.
//

import Foundation


class RecorderParamService {
    static func getRecorderParamsForThisDevice(_ useMotor: Bool) -> RecorderParamInfo {
        var info = RecorderParamInfo()
        
        // This graph config for all phones
        info.graphVOverlap = 0.25
        info.tolerance = 1
        
        // Device type determines horizontal buffer
        // Horizontal buffer 0.9 needs twice as much images ans 0.8 (see recorder graph why)
        switch UIDevice.current.deviceType {
            case .iPhone5, .iPhone5S, .iPhone6:
                info.stereoHBuffer = 0.8
                info.graphHOverlap = 0.8
            default:
                info.stereoHBuffer = 1.6
                info.graphHOverlap = 0.9
        }
        
        // Using motor determines vetical offsets and sparseness
        if useMotor {
            info.halfGraph = true
            info.stereoVBuffer = 0.00
        } else {
            info.halfGraph = false
            info.stereoVBuffer = -0.03
        }
        
        
        return info
    }
}

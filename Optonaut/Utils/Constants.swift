//
//  Constants.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/29/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import Device

let OnboardingVersion: Int = 1

let HorizontalFieldOfView: Float = 45

enum EnvType {
    case development
    case staging
    case production
    case localStaging
}

var S3URL: String {
    switch Env {
    case .development: return "http://optonaut-ios-beta-dev.s3.amazonaws.com"
    case .staging: return "http://optonaut-ios-beta-staging.s3.amazonaws.com"
    case .localStaging: return "http://192.168.1.69:3000"
    case .production: return "http://optonaut-ios-beta-production.s3.amazonaws.com"
    }
}

let CameraIntrinsics: GLKMatrix3 = {
    switch UIDevice.current.deviceType {
    case .iPhone5, .iPhone5S: return Recorder.getIPhone5Intrinsics()
    default: return Recorder.getIPhone6Intrinsics()
    }
}()

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

enum EnvType {
    case Development
    case Staging
    case Production
}

var S3URL: String {
    switch Env {
    case .Development: return "http://optonaut-ios-beta-dev.s3.amazonaws.com"
    case .Staging: return "http://optonaut-ios-beta-staging.s3.amazonaws.com"
    case .Production: return "http://optonaut-ios-beta-production.s3.amazonaws.com"
    }
}

let CameraIntrinsics: GLKMatrix3 = {
    switch UIDevice.currentDevice().deviceType {
    case .IPhone6, .IPhone6S, .IPhone6SPlus, .IPhone5S: return Recorder.getIPhone6Intrinsics()
    case .IPhone5: return Recorder.getIPhone5Intrinsics()
    default: return GLKMatrix3Identity
    }
}()
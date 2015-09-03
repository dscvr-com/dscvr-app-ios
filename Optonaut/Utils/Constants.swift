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

enum EnvType {
    case Development
    case Staging
    case Production
}

//let Env = EnvType.Development
let Env = EnvType.Staging
//let Env = EnvType.Production

var S3URL: String {
    switch Env {
    case .Development: return "http://optonaut-ios-beta-dev.s3.amazonaws.com"
    case .Staging: return "http://optonaut-ios-beta-staging.s3.amazonaws.com"
    case .Production: return "http://optonaut-ios-beta-production.s3.amazonaws.com"
    }
}

let StaticPath: String = {
    let appId = NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"] as? NSString
    let path = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first! + "/\(appId!)/static"
    try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
    return path
}()

let CameraIntrinsics: [Double] = {
    switch UIDevice.currentDevice().deviceType {
    case .IPhone6: return [6.9034, 0, 1.6875, 0, 6.9034, 3, 0, 0, 1]
    case .IPhone5S: return [6.9034, 0, 1.6875, 0, 6.9034, 3, 0, 0, 1]
    case .IPhone5: return [5.49075, 0, 1.276875, 0, 4.1, 2.27, 0, 0, 1]
    default: return []
    }
}()
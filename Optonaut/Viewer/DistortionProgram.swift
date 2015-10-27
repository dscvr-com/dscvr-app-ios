//
//  DistortionProgram.swift
//  Optonaut
//
//  Created by Emi on 25/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SceneKit
import GoogleCardboardParser

enum Eye {
    case Left
    case Right
}

// TODO: Param for flipping 180
class DistortionProgram {
    let technique: SCNTechnique
    let fov: FieldOfView
    private let coefficients: CGSize
    private let eyeOffset: CGSize

    
    init(distortion: Distortion, fov: FieldOfView, eyeOffsetX: Float, eyeOffsetY: Float) {
        technique = DistortionProgram.techniqueFromName("distortion")
        
        coefficients = CGSize(width: CGFloat(distortion.coefficients[0]), height: CGFloat(distortion.coefficients[1]))
        eyeOffset = CGSize(width: CGFloat(eyeOffsetX), height: CGFloat(eyeOffsetY))
        
        print("Coefficients")
        print(coefficients)
        print("EyeOffset")
        print(eyeOffset)
        
        let factor = distortion.distortInverse(0.9)
        print("dFactor")
        print(factor)
        
        technique.setValue(NSValue(CGSize: coefficients), forKey: "coefficients")
        technique.setValue(NSValue(CGSize: eyeOffset), forKey: "eye_offset")
        technique.setValue(NSNumber(float: factor), forKey: "texture_scale")
        technique.setValue(NSNumber(float: 0.05), forKey: "vignette_x")
        technique.setValue(NSNumber(float: 0.02), forKey: "vignette_y")
        
        self.fov = fov
    }
    
    static func truncateFov(originalFov: Float, offset: Float) -> Float {
        
        if offset <= 0 {
            return originalFov
        }
        
        
        return toDegrees(toRadians(originalFov) - asin(sin(toRadians(originalFov)) * offset))
    }
    
    convenience init(params: CardboardParams, screen: ScreenParams, eye: Eye) {
        
        print(screen)
        print(params)
        
        //TODO: update frustum to fit those params. 
        //Shouldnt be that hard. just get the right texture crop
        
        var xEyeOffsetTanAngleScreen = (params.getYEyeOffsetMeters(screen) - screen.widthMeters / Float(2)) / screen.widthMeters
        
        var yEyeOffsetTanAngleScreen = (screen.heightMeters / Float(4.0) - params.interLensDistance / Float(2.0)) / screen.heightMeters
        
        if eye == .Right {
            yEyeOffsetTanAngleScreen = -yEyeOffsetTanAngleScreen
        }
        
        xEyeOffsetTanAngleScreen *= 2
        yEyeOffsetTanAngleScreen *= -2
        
        let fovLeft = DistortionProgram.truncateFov(params.leftEyeMaxFov.left, offset: -xEyeOffsetTanAngleScreen)
        let fovRight = DistortionProgram.truncateFov(params.leftEyeMaxFov.right, offset: xEyeOffsetTanAngleScreen)
        let fovTop = DistortionProgram.truncateFov(params.leftEyeMaxFov.top, offset: -yEyeOffsetTanAngleScreen)
        let fovBottom = DistortionProgram.truncateFov(params.leftEyeMaxFov.bottom, offset: yEyeOffsetTanAngleScreen)
        

        let newFov = FieldOfView(angles: [fovLeft, fovRight, fovTop, fovBottom])
        
        self.init(distortion: Distortion(coefficients: params.distortionCoefficients), fov: newFov, eyeOffsetX: xEyeOffsetTanAngleScreen, eyeOffsetY: yEyeOffsetTanAngleScreen)
    }
    
    static func toRadians(deg: Float) -> Float {
        return deg / Float(180) * Float(M_PI)
    }
    
    static func toDegrees(rad: Float) -> Float {
        return rad * Float(180) / Float(M_PI)
    }
    
    static func techniqueFromName(name: String) -> SCNTechnique {
        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(name, ofType: "json")!)
        let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
        let technique = SCNTechnique(dictionary: json as! [String : AnyObject])
        
        return technique!
    }
}
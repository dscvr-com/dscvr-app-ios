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
    private let coefficients: CGSize
    private let eyeOffset: CGSize

    
    init(distortion: Distortion, eyeOffsetX: Float, eyeOffsetY: Float) {
        technique = DistortionProgram.techniqueFromName("distortion")
        
        coefficients = CGSize(width: CGFloat(distortion.coefficients[0]), height: CGFloat(distortion.coefficients[1]))
        eyeOffset = CGSize(width: CGFloat(eyeOffsetX), height: CGFloat(eyeOffsetY))
        
        print("Coefficients")
        print(coefficients)
        print("EyeOffset")
        print(eyeOffset)
        
        let factor = distortion.distortInverse(1)
        print("dFactor")
        print(factor)
        
        technique.setValue(NSValue(CGSize: coefficients), forKey: "coefficients")
        technique.setValue(NSValue(CGSize: eyeOffset), forKey: "eye_offset")
        technique.setValue(NSNumber(float: factor), forKey: "texture_scale")
    }
    
    convenience init(params: CardboardParams, screen: ScreenParams, eye: Eye) {
        
        print(screen)
        print(params)
        
        
        let metersPerTanAngle = screen.widthMeters
    
        var xEyeOffsetTanAngleScreen = (params.getYEyeOffsetMeters(screen)) / metersPerTanAngle
        
        var yEyeOffsetTanAngleScreen = (screen.heightMeters / Float(2.0) - params.interLensDistance / Float(2.0)) / metersPerTanAngle
        
        if eye == .Right {
            yEyeOffsetTanAngleScreen = (screen.heightMeters / Float(2.0)) - yEyeOffsetTanAngleScreen
        }
        
        xEyeOffsetTanAngleScreen -= 0.5
        xEyeOffsetTanAngleScreen *= 2
        
        self.init(distortion: Distortion(coefficients: params.distortionCoefficients), eyeOffsetX: xEyeOffsetTanAngleScreen, eyeOffsetY: yEyeOffsetTanAngleScreen)
    }

    func toRadians(deg: Float) -> Float {
        return deg / Float(180) * Float(M_PI)
    }
    
    static func techniqueFromName(name: String) -> SCNTechnique {
        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(name, ofType: "json")!)
        let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
        let technique = SCNTechnique(dictionary: json as! [String : AnyObject])
        
        return technique!
    }
}
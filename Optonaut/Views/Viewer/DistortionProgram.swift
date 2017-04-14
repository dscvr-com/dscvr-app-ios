//
//  DistortionProgram.swift
//  Optonaut
//
//  Created by Emi on 25/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SceneKit
import CardboardParams

enum Eye {
    case left
    case right
}


protocol DistortionProgram {
    var technique: SCNTechnique! { get }
    var fov: FieldOfView! { get }
    
    func setParameters(_ params: CardboardParams, screen: ScreenParams, eye: Eye)
}

class DistortionProgramHelpers {
    
    static func techniqueFromName(_ name: String) -> SCNTechnique {
        let data = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: name, ofType: "json")!))
        let json = try! JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSDictionary
        let technique = SCNTechnique(dictionary: json as! [String : AnyObject])
        
        return technique!
    }
    
    
    static func truncateFov(_ originalFov: Float, offset: Float) -> Float {
        if offset <= 0 {
            return originalFov
        }
        return toDegrees(toRadians(originalFov) - atan(tan(toRadians(originalFov)) * offset))
    }

}

class VROneDistortionProgram: DistortionProgram {
    
    fileprivate(set) var technique: SCNTechnique!
    fileprivate(set) var fov: FieldOfView!
    
    init(isLeft: Bool) {
        if isLeft {
            technique = DistortionProgramHelpers.techniqueFromName("zeiss_displacement_left")
        } else {
            technique = DistortionProgramHelpers.techniqueFromName("zeiss_displacement_right")
        }
        
        fov = FieldOfView(angles: [50, 50, 50, 50])
    }
    
    
    func setParameters(_ params: CardboardParams, screen: ScreenParams, eye: Eye) { }
}
class CardboardDistortionProgram: DistortionProgram {
    fileprivate(set) var technique: SCNTechnique!
    fileprivate(set) var fov: FieldOfView!
    fileprivate var coefficients: CGSize!
    fileprivate var eyeOffset: CGSize!

    init(params: CardboardParams, screen: ScreenParams, eye: Eye) {
        technique = DistortionProgramHelpers.techniqueFromName("distortion")
        
        setParameters(params, screen: screen, eye: eye)
    }
    
    func setParameters(_ params: CardboardParams, screen: ScreenParams, eye: Eye) {
        
        var xEyeOffsetTanAngleScreen = (params.getYEyeOffsetMeters(screen) - screen.widthMeters / Float(2)) / screen.widthMeters
        
        var yEyeOffsetTanAngleScreen = (screen.heightMeters / Float(4.0) - params.interLensDistance / Float(2.0)) / screen.heightMeters
        
        if eye == .right {
            yEyeOffsetTanAngleScreen = -yEyeOffsetTanAngleScreen
        }
        
        xEyeOffsetTanAngleScreen *= 2
        yEyeOffsetTanAngleScreen *= -4
        
        let fovLeft = DistortionProgramHelpers.truncateFov(params.leftEyeMaxFov.left, offset: -xEyeOffsetTanAngleScreen)
        let fovRight = DistortionProgramHelpers.truncateFov(params.leftEyeMaxFov.right, offset: xEyeOffsetTanAngleScreen)
        let fovTop = DistortionProgramHelpers.truncateFov(params.leftEyeMaxFov.top, offset: yEyeOffsetTanAngleScreen)
        let fovBottom = DistortionProgramHelpers.truncateFov(params.leftEyeMaxFov.bottom, offset: -yEyeOffsetTanAngleScreen)
        

        let newFov = FieldOfView(angles: [fovLeft, fovRight, fovTop, fovBottom])
        
        self.setParameters(Distortion(coefficients: params.distortionCoefficients), fov: newFov, eyeOffsetX: xEyeOffsetTanAngleScreen, eyeOffsetY: yEyeOffsetTanAngleScreen)
    }
    
    func setParameters(_ distortion: Distortion, fov: FieldOfView, eyeOffsetX: Float, eyeOffsetY: Float) {
        coefficients = CGSize(width: CGFloat(distortion.coefficients[0]), height: CGFloat(distortion.coefficients[1]))
        //coefficients = CGSize(width: 0, height: 0)
        eyeOffset = CGSize(width: CGFloat(eyeOffsetX), height: CGFloat(eyeOffsetY))
        
        let factor = distortion.distortInverse(1 - eyeOffsetX / 2)
        let viewportOffset = CGSize(width: CGFloat(eyeOffsetX / 2), height: CGFloat(eyeOffsetY / 2))
        //let viewportOffset = CGSize(width: 0, height: 0)
        
        print("Texture Scale \(factor)")
        
        technique.setValue(NSValue(cgSize: coefficients), forKey: "coefficients")
        technique.setValue(NSValue(cgSize: eyeOffset), forKey: "eye_offset")
        technique.setValue(NSValue(cgSize: viewportOffset), forKey: "viewport_offset")
        technique.setValue(NSNumber(value: factor as Float), forKey: "texture_scale")
        technique.setValue(NSNumber(value: 0.05 as Float), forKey: "vignette_x")
        technique.setValue(NSNumber(value: 0.02 as Float), forKey: "vignette_y")
        
        self.fov = fov
    }
}

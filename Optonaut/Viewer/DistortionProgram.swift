//
//  DistortionProgram.swift
//  Optonaut
//
//  Created by Emi on 25/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SceneKit

class DistortionProgram {
    private let textureCoordScaleUniform = "uTextureCoordScale"
    private let technique: SCNTechnique

    init(textureScoordScale: Float) {
        technique = DistortionProgram.techniqueFromName("distortion")
        technique.setValue(NSNumber(float: textureScoordScale), forKey: textureCoordScaleUniform)
    }
    
    static func techniqueFromName(name: String) -> SCNTechnique {
        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(name, ofType: "json")!)
        let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
        let technique = SCNTechnique(dictionary: json as! [String : AnyObject])
        
        return technique!
    }
}
//
//  StereoRenderDelegate.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/11/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SceneKit

class StereoRenderDelegate: NSObject, SCNSceneRendererDelegate {
    
    let scene = SCNScene()
    var image: UIImage? {
        didSet {
            sphereNode.geometry?.firstMaterial?.diffuse.contents = image
        }
    }

    private let cameraNode: SCNNode
    private let sphereNode: SCNNode
    private let rotationMatrixSource: RotationMatrixSource
    
    init(rotationMatrixSource: RotationMatrixSource, width: CGFloat, height: CGFloat, fov: Double) {
        self.rotationMatrixSource = rotationMatrixSource
        
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 10000
        camera.xFov = fov
        camera.yFov = fov * Double(width / height)
        
        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(cameraNode)
        
        sphereNode = StereoRenderDelegate.createSphere()
        scene.rootNode.addChildNode(sphereNode)
        
        super.init()
    }

    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        cameraNode.transform = SCNMatrix4FromGLKMatrix4(rotationMatrixSource.getRotationMatrix())
    }
    
    private static func createSphere() -> SCNNode {
        // rotate sphere to correctly display texture
        let transform = SCNMatrix4Scale(SCNMatrix4MakeRotation(Float(M_PI_2), 1, 0, 0), -1, 1, 1)
        
        let geometry = SCNSphere(radius: 5.0)
        geometry.segmentCount = 128
        geometry.firstMaterial?.doubleSided = true
        geometry.firstMaterial?.diffuse.contents = UIColor.clearColor()
        
        let node = SCNNode(geometry: geometry)
        node.transform = transform
        
        return node
    }
    
}
//
//  StereoRenderDelegate.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/11/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SceneKit
import CardboardParams
import SpriteKit

class StereoRenderDelegate: NSObject, SCNSceneRendererDelegate {
    
    let scene = SCNScene()
    var image: SKTexture? {
        didSet {
            guard let image = image else {
                sphereNode.geometry?.firstMaterial?.diffuse.contents = nil
                return
            }
            
            if image.size().width == image.size().height {
                // Classic case - quadratic texture
                sphereNode.geometry?.firstMaterial?.diffuse.contents = nil
                sphereNode.geometry?.firstMaterial?.diffuse.contents = image
            } else {
                // Extended case - rectangular texture, need to center
                let ratio = Float((image.size().width / CGFloat(2)) / image.size().height)
                sphereNode.geometry?.firstMaterial?.diffuse.contents = image
                
                // Yes, we calculate our transform ourselves.
                // And yes, this matrix is inverted.
                // Texture mapping from 0 to 1
                let transform = SCNMatrix4FromGLKMatrix4(
                    GLKMatrix4Make(
                        1, 0, 0, 0,
                        0, -ratio, 0, 0,
                        0, 0, 1, 0,
                        0, 1 - (1 - ratio) / 2, 0, 1
                    )
                )
                
                sphereNode.geometry?.firstMaterial?.diffuse.contentsTransform = transform
                if #available(iOS 9.0, *) {
                    sphereNode.geometry?.firstMaterial?.diffuse.wrapS = .ClampToBorder
                    sphereNode.geometry?.firstMaterial?.diffuse.wrapT = .ClampToBorder
                } else {
                    
                }
                sphereNode.geometry?.firstMaterial?.diffuse.borderColor =  UIColor.blackColor()

            }
        }
    }

    private var cameraNode: SCNNode!
    let sphereNode: SCNNode
    private let rotationMatrixSource: RotationMatrixSource
    private var _fov: FieldOfView!
    private let cameraOffset: Float
    
    var fov: FieldOfView {
        get {
            return _fov
        }
        set {
            _fov = fov
            cameraNode.camera = StereoRenderDelegate.setupCamera(fov)
        }
    }

    init(rotationMatrixSource: RotationMatrixSource, width: CGFloat, height: CGFloat, fov: FieldOfView, cameraOffset: Float) {
        self.rotationMatrixSource = rotationMatrixSource
        self.cameraOffset = cameraOffset
        
        cameraNode = SCNNode()
        
        cameraNode.camera = StereoRenderDelegate.setupCamera(fov)
        _fov = fov
        
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(cameraNode)
        
        cameraNode.pivot = SCNMatrix4MakeTranslation(0, cameraOffset, 0)
        
        sphereNode = StereoRenderDelegate.createSphere()
        scene.rootNode.addChildNode(sphereNode)
        
        super.init()
    }
    
    private static func setupCamera(fov: FieldOfView) -> SCNCamera {
        let zNear = Float(0.01)
        let zFar = Float(10000)
        
//        print("Fov:")
//        print(fov)
        
        let fovLeft = tan(toRadians(fov.left)) * zNear
        let fovRight = tan(toRadians(fov.right)) * zNear
        let fovTop = tan(toRadians(fov.top)) * zNear
        let fovBottom = tan(toRadians(fov.bottom)) * zNear
        
        let projection = GLKMatrix4MakeFrustum(-fovLeft, fovRight, -fovBottom, fovTop, zNear, zFar)
        
        let camera = SCNCamera()
        camera.setProjectionTransform(SCNMatrix4FromGLKMatrix4(projection))
        
        return camera
    }
    
    convenience init(rotationMatrixSource: RotationMatrixSource, width: CGFloat, height: CGFloat, fov: Double) {
        let xFov = Float(fov)
        let yFov = toDegrees(
            atan(
                tan(toRadians(xFov) / Float(2)) * Float(height / width)
            ) * Float(2)
        )
        let angles: [Float] = [xFov / Float(2.0), xFov / Float(2.0), yFov / Float(2.0), yFov / Float(2.0)]
        let newFov = FieldOfView(angles: angles)
        
        self.init(rotationMatrixSource: rotationMatrixSource, width: width, height: height, fov: newFov, cameraOffset: Float(0))
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
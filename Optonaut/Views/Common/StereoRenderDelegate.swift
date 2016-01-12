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

private let d: CGFloat = 10

class StereoRenderDelegate: NSObject, SCNSceneRendererDelegate {

    let scene = SCNScene()
    private var cameraNode: SCNNode
    private let rotationMatrixSource: RotationMatrixSource
    private var _fov: FieldOfView
    private let cameraOffset: Float
    
    var planes: [CubeImageCache.Index: SCNNode] = [:]
    
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
        
//        sphereNode = StereoRenderDelegate.createSphere()
        let transforms: [(position: SCNVector3, rotation: SCNVector3)] = [
            (SCNVector3Make(0, 0, Float(d)), SCNVector3Make(0, 0, 0)),
            (SCNVector3Make(Float(d), 0, 0), SCNVector3Make(0, Float(M_PI_2), 0)),
            (SCNVector3Make(0, 0, Float(-d)), SCNVector3Make(0, Float(M_PI), 0)),
            (SCNVector3Make(Float(-d), 0, 0), SCNVector3Make(0, Float(-M_PI_2), 0)),
            (SCNVector3Make(0, Float(d), 0), SCNVector3Make(Float(-M_PI_2), Float(-M_PI_2), 0)),
            (SCNVector3Make(0, Float(-d), 0), SCNVector3Make(Float(M_PI_2), Float(-M_PI_2), 0)),
        ]
        for face in 0..<6 {
            let node = StereoRenderDelegate.createPlane(position: transforms[face].position, rotation: transforms[face].rotation)
            planes[CubeImageCache.Index(face: face, x: 0, y: 0, d: 1)] = node
            scene.rootNode.addChildNode(node)
        }
        
        super.init()
    }
    
    func setTexture(texture: SKTexture, forIndex index: CubeImageCache.Index) {
        planes[index]!.geometry!.firstMaterial!.diffuse.contents = texture
    }
    
    private static func setupCamera(fov: FieldOfView) -> SCNCamera {
        let zNear = Float(0.01)
        let zFar = Float(10000)
        
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
    
    private static func createPlane(position position: SCNVector3, rotation: SCNVector3) -> SCNNode {
        let geometry = SCNPlane(width: 2 * d, height: 2 * d)
        geometry.firstMaterial!.doubleSided = true
        
        let node = SCNNode(geometry: geometry)
        
        node.position = position
        node.eulerAngles = rotation
        
        let transform = SCNMatrix4Scale(SCNMatrix4MakeRotation(Float(M_PI_2), 1, 0, 0), -1, 1, 1)
        node.transform = SCNMatrix4Mult(node.transform, transform)
        
        return node
    }
    
}
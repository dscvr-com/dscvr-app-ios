//
//  RenderDelegate.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/11/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SceneKit
import CardboardParams
import SpriteKit

class RenderDelegate: NSObject, SCNSceneRendererDelegate {

    private let cameraNode = SCNNode()
    private let rotationMatrixSource: RotationMatrixSource
    private let cameraOffset: Float
    
    let scene = SCNScene()
    
    private var _fov: FieldOfView
    var fov: FieldOfView {
        get {
            return _fov
        }
        set {
            _fov = fov
            cameraNode.camera = RenderDelegate.setupCamera(fov)
        }
    }

    init(rotationMatrixSource: RotationMatrixSource, fov: FieldOfView, cameraOffset: Float) {
        self.rotationMatrixSource = rotationMatrixSource
        self.cameraOffset = cameraOffset
        
        cameraNode.camera = RenderDelegate.setupCamera(fov)
        _fov = fov
        
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(cameraNode)
        
        // TODO(ej): Check if this is necassary for 3D vision. If so, add it to transform
        // in each render loop since pivot is broken.
        // cameraNode.pivot = SCNMatrix4MakeTranslation(0, cameraOffset, 0)
        
        super.init()
    }
    
    convenience init(rotationMatrixSource: RotationMatrixSource, width: CGFloat, height: CGFloat, fov: Double) {
        let newFov = RenderDelegate.getFov(width, height: height, fov: fov)
        
        self.init(rotationMatrixSource: rotationMatrixSource, fov: newFov, cameraOffset: Float(0))
    }
    
    internal static func getFov(width: CGFloat, height: CGFloat, fov: Double) -> FieldOfView {
        let xFov = Float(fov)
        let yFov = toDegrees(
            atan(
                tan(toRadians(xFov) / Float(2)) * Float(height / width)
                ) * Float(2)
        )
        let angles = [xFov / Float(2.0), xFov / Float(2.0), yFov / Float(2.0), yFov / Float(2.0)]
        return FieldOfView(angles: angles)
    }
    
    internal static func setupCamera(fov: FieldOfView) -> SCNCamera {
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
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        cameraNode.transform = SCNMatrix4FromGLKMatrix4(rotationMatrixSource.getRotationMatrix())
    }
    
}

class CubeRenderDelegate: RenderDelegate {
    
    class Item {
        let node: SCNNode
        var visible: Bool
        
        init(node: SCNNode, visible: Bool) {
            self.node = node
            self.visible = visible
        }
    }
    
    var planes: [CubeImageCache.Index: Item] = [:]
    // Inverse index lookup from node to index
    var indices: [SCNNode: CubeImageCache.Index] = [:]
    var adj: [SCNNode: [SCNNode]] = [:]
    
    var nodeEnterScene: (CubeImageCache.Index -> ())?
    var nodeLeaveScene: (CubeImageCache.Index -> ())?
    
    weak var scnView: SCNView?

    private let cubeScaling: CGFloat = 10
    
    override init(rotationMatrixSource: RotationMatrixSource, fov: FieldOfView, cameraOffset: Float) {
        super.init(rotationMatrixSource: rotationMatrixSource, fov: fov, cameraOffset: cameraOffset)
        
        initScene()
    }
    
    
    private static func getBlackTexture() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1));
        let contextRef = UIGraphicsGetCurrentContext()
        UIColor.blackColor().setFill()
        CGContextFillRect(contextRef, CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private static let BlackTexture = CubeRenderDelegate.getBlackTexture()
    
    private func initScene() {
        let subSurf = 3
        
        let subW = 1.0 / Float(subSurf)
        
        let transforms: [(position: SCNVector3, rotation: SCNVector3)] = [
            (SCNVector3Make(0, 0, 1), SCNVector3Make(0, 0, 0)),
            (SCNVector3Make(1, 0, 0), SCNVector3Make(0, Float(M_PI_2), 0)),
            (SCNVector3Make(0, 0, -1), SCNVector3Make(0, Float(M_PI), 0)),
            (SCNVector3Make(-1, 0, 0), SCNVector3Make(0, Float(-M_PI_2), 0)),
            (SCNVector3Make(0, 1, 0), SCNVector3Make(Float(-M_PI_2), Float(-M_PI_2), 0)),
            (SCNVector3Make(0, -1, 0), SCNVector3Make(Float(M_PI_2), Float(-M_PI_2), 0)),
        ]
        
        for face in 0..<6 {
            for subX in 0..<subSurf {
                for subY in 0..<subSurf {
                    let node = createPlane(position: transforms[face].position, rotation: transforms[face].rotation,
                        subX: Float(subX) * subW, subY: Float(subY) * subW, subW: subW)
                    node.geometry!.firstMaterial!.doubleSided = true
                    
                    let index = CubeImageCache.Index(face: face, x: Float(subX) * subW, y: Float(subY) * subW, d: subW)
                    
                    planes[index] = Item(node: node, visible: false)
                    indices[node] = index
                    scene.rootNode.addChildNode(node)
                }
            }
        }
        
        for o in planes.values {
            adj[o.node] = getKNNGeometric(o.node, k: 9)
        }
    }
    
    private func getDist(a: SCNNode, b: SCNNode) -> Float {
        let diff = GLKVector3Subtract(
            SCNVector3ToGLKVector3(a.position),
            SCNVector3ToGLKVector3(b.position))

        return GLKVector3Length(diff)
    }
    
    private func getKNNGeometric(center: SCNNode, k: Int) -> [SCNNode] {
        let allNodes = planes.values.map { $0.node }
        let sorted = allNodes.sort { (n1: SCNNode, n2: SCNNode) in getDist(center, b: n1) < getDist(center, b: n2) }
        return [SCNNode](sorted.prefix(k))
    }
    
    func setTexture(texture: SKTexture, forIndex index: CubeImageCache.Index) {
        if let node = planes[index]?.node {
            print("settex \(id) \(index)")
            sync(self) {
                assert(node.geometry!.firstMaterial!.diffuse.contents !== texture) // Don't overwrite textures!
                assert(node.geometry!.firstMaterial!.diffuse.contents === CubeRenderDelegate.BlackTexture) // Don't overwrite textures!
                node.geometry!.firstMaterial!.diffuse.contents = texture
            }
        }
    }
    
    var id: Int = 0
    
    func reset() {
        self.nodeEnterScene = nil
        self.nodeLeaveScene = nil
        
        sync(self) {
            for (index, plane) in self.planes {
                print("resett \(self.id) \(index)")
                plane.node.geometry?.firstMaterial?.diffuse.contents = CubeRenderDelegate.BlackTexture
                plane.visible = false
            }
        }
    }
    
    func getVisibleAndAdjacentPlaneIndicesFromRotationMatrix(rotation: GLKMatrix4) -> [CubeImageCache.Index] {
        let dummyCam = SCNNode()
        dummyCam.camera = cameraNode.camera
        dummyCam.transform = SCNMatrix4FromGLKMatrix4(rotation)
        
        return getVisibleAndAdjacentPlanes(dummyCam).map { indices[$0]! }
    }
    
    private func getVisibleAndAdjacentPlanes(camera: SCNNode) -> Set<SCNNode> {
        let visiblePlanes: [SCNNode] = planes.values.map { $0.node }.filter { (self.scnView!.isNodeInsideFrustum($0, withPointOfView: camera)) }
        return Set(visiblePlanes.flatMap { self.adj[$0]! })
    }
    
    override func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        super.renderer(aRenderer, updateAtTime: time)
        
        // Use the small camera for debugging.
        // let smallFov = RenderDelegate.getFov(scnView!.bounds.width, height: scnView!.bounds.height, fov: 10)
        // let smallCamera = SCNNode()
        // smallCamera.camera = RenderDelegate.setupCamera(smallFov)
        // smallCamera.transform = cameraNode.transform
        
        let visibleAndAdjacentPlanes = getVisibleAndAdjacentPlanes(self.cameraNode)
        
        // Use verbose colors for debugging.
        // planes.values.forEach { $0.node.geometry!.firstMaterial!.diffuse.contents = UIColor.redColor() }
        // visibleAndAdjacentPlanes.forEach { $0.geometry!.firstMaterial!.diffuse.contents = UIColor.blueColor() }
        // visiblePlanes.forEach { $0.geometry!.firstMaterial!.diffuse.contents = UIColor.greenColor() }
        
        for (index, item) in planes {
            let nowVisible = visibleAndAdjacentPlanes.contains(item.node)
            if nowVisible && !item.visible {
                if let callback = nodeEnterScene {
                    callback(index)
                    item.visible = true
                }
            } else if !nowVisible && item.visible {
                sync(self) {
                    if item.node.geometry!.firstMaterial!.diffuse.contents !== CubeRenderDelegate.BlackTexture {
                        print("forget \(self.id) \(index)")
                        item.node.geometry!.firstMaterial!.diffuse.contents = CubeRenderDelegate.BlackTexture
                        
                        if let callback = self.nodeLeaveScene {
                            item.visible = false
                            callback(index)
                        }
                    }
                }
            }
        }
        
    }
    
    private func createPlane(position position: SCNVector3, rotation: SCNVector3, subX: Float, subY: Float, subW: Float) -> SCNNode {
        let geometry = SCNPlane(width: CGFloat(2 * subW), height: CGFloat(2 * subW))
        geometry.firstMaterial!.doubleSided = true
        
        geometry.firstMaterial!.diffuse.contents = CubeRenderDelegate.BlackTexture
        
        let node = SCNNode(geometry: geometry)
        
        let pivot = SCNMatrix4MakeTranslation(-(subX + subW / 2) * 2 + 1, (subY + subW / 2) * 2 - 1, 0)
        
        node.position = position
        node.eulerAngles = rotation
        
        var transform = SCNMatrix4Scale(SCNMatrix4MakeRotation(Float(M_PI_2), 1, 0, 0), -1, 1, 1)
        transform = SCNMatrix4Mult(node.transform, transform)
        node.transform = SCNMatrix4Mult(SCNMatrix4Invert(pivot), transform)

        return node
    }
    
}

class SphereRenderDelegate: RenderDelegate {
    
    let sphereNode: SCNNode
    
    var image: UIImage? {
        didSet {
            guard let image = image else {
                sphereNode.geometry?.firstMaterial?.diffuse.contents = nil
                return
            }
            
            if image.size.width == image.size.height {
                // Classic case - quadratic texture
                sphereNode.geometry?.firstMaterial?.diffuse.contents = nil
                sphereNode.geometry?.firstMaterial?.diffuse.contents = image
            } else {
                // Extended case - rectangular texture, need to center
                let ratio = Float((image.size.width / CGFloat(2)) / image.size.height)
                sphereNode.geometry?.firstMaterial?.diffuse.contents = image
                
                // Yes, we calculate our transform ourselves.
                // And yes, this matrix is inverted.
                // Texture mapping from 0 to 1
                let transform = SCNMatrix4FromGLKMatrix4(
                    GLKMatrix4Make(
                        1, 0, 0, 0,
                        0, ratio, 0, 0,
                        0, 0, 1, 0,
                        0, (1 - ratio) / 2, 0, 1
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
    var texture: SKTexture? {
        didSet {
            guard let image = texture else {
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

    
    override init(rotationMatrixSource: RotationMatrixSource, fov: FieldOfView, cameraOffset: Float) {
        sphereNode = SphereRenderDelegate.createSphere()
        
        super.init(rotationMatrixSource: rotationMatrixSource, fov: fov, cameraOffset: cameraOffset)
        
        scene.rootNode.addChildNode(sphereNode)
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
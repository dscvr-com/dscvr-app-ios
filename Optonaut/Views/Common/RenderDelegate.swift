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
import ReactiveCocoa

//protocol RenderDelegateDelegate {
//    func didEnterFrustrum(markerName: String)
//}

class RenderDelegate: NSObject, SCNSceneRendererDelegate {

    private let cameraNode = SCNNode()
    private let cameraCrosshair =  SCNNode()
    
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
            
            cameraCrosshair.camera = RenderDelegate.setupCrosshairCamera(fov)
        }
    }

    init(rotationMatrixSource: RotationMatrixSource, fov: FieldOfView, cameraOffset: Float) {
        self.rotationMatrixSource = rotationMatrixSource
        self.cameraOffset = cameraOffset
        
        cameraNode.camera = RenderDelegate.setupCamera(fov)
        _fov = fov
     
        cameraCrosshair.camera = RenderDelegate.setupCrosshairCamera(fov)
        
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(cameraNode)
        
    
        cameraCrosshair.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(cameraCrosshair)
        
        // TODO(ej): Check if this is necassary for 3D vision. If so, add it to transform
        // in each render loop since pivot is broken.
        // cameraNode.pivot = SCNMatrix4MakeTranslation(0, cameraOffset, 0)
        
        
        super.init()
    }
    
//    var delegate: RenderDelegateDelegate?
    
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
    
    internal static func setupCrosshairCamera(fov: FieldOfView) -> SCNCamera {
        let zNear = Float(0.01)
        let zFar = Float(10000)
        
        let fovLeft = tan(toRadians(fov.left)) * zNear
        let fovRight = tan(toRadians(fov.right)) * zNear
        let fovTop = tan(toRadians(fov.top)) * zNear
        let fovBottom = tan(toRadians(fov.bottom)) * zNear
        
        let projection = GLKMatrix4MakeFrustum(-fovLeft/16, fovRight/16, -fovBottom/16, fovTop/16, zNear, zFar)
        
        let camera = SCNCamera()
        camera.setProjectionTransform(SCNMatrix4FromGLKMatrix4(projection))
        
        return camera
    }
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        cameraNode.transform = SCNMatrix4FromGLKMatrix4(rotationMatrixSource.getRotationMatrix())
        
        
        cameraCrosshair.transform = SCNMatrix4FromGLKMatrix4(rotationMatrixSource.getRotationMatrix())
    }
    
    func dispose() {
        scene.rootNode.childNodes.forEach {
            $0.removeFromParentNode()
        }
    }
    
}

protocol CubeRenderDelegateDelegate {
    func didEnterFrustrum(markerName: String, inFrustrum: Bool)
    func addVectorAndRotation(vector: SCNVector3, rotation: SCNVector3)
}

class CubeRenderDelegate: RenderDelegate {
    
    class Item {
        let node: SCNNode
        var visible: Bool
        var requested: Bool
        var hasTexture: Bool
        
        init(node: SCNNode, visible: Bool) {
            self.node = node
            self.visible = visible
            self.requested = false
            self.hasTexture = false
        }
    }
    
    var planes: [CubeImageCache.Index: Item] = [:]
    // Inverse index lookup from node to index
    var indices: [SCNNode: CubeImageCache.Index] = [:]
    var adj: [SCNNode: [SCNNode]] = [:]
    var markers = [SCNNode] ()
    
    var nodeEnterScene: (CubeImageCache.Index -> ())?
    var nodeLeaveScene: (CubeImageCache.Index -> ())?
    
    var delegate: CubeRenderDelegateDelegate?
    
    weak var scnView: SCNView?
    private let sphereGeoNode: SCNNode
    private let cameraText: SCNNode
   
    private let cubeScaling: CGFloat = 10
    private let cubeFaceCount: Int
    private let autoDispose: Bool
    private var willRequestAll: Bool
    let imageCache: CollectionImageCache
    
   
    convenience init(rotationMatrixSource: RotationMatrixSource, width: CGFloat, height: CGFloat, fov: Double, cubeFaceCount: Int, autoDispose: Bool) {
        let newFov = RenderDelegate.getFov(width, height: height, fov: fov)
        
        self.init(rotationMatrixSource: rotationMatrixSource, fov: newFov, cameraOffset: Float(0), cubeFaceCount: cubeFaceCount, autoDispose: autoDispose)
    }
    
    init(rotationMatrixSource: RotationMatrixSource, fov: FieldOfView, cameraOffset: Float, cubeFaceCount: Int, autoDispose: Bool) {
        self.cubeFaceCount = cubeFaceCount
        self.autoDispose = autoDispose
        self.willRequestAll = false
        
        scnView?.showsStatistics = true
        
        let planeGeo = SCNPlane(width: 1.0, height: 1.0)
        planeGeo.firstMaterial?.diffuse.contents = UIColor.clearColor()
        
        
        let circleGeo = SCNSphere(radius: 0.01)
        circleGeo.firstMaterial?.diffuse.contents = UIColor.clearColor()
        sphereGeoNode = SCNNode(geometry: circleGeo)
        sphereGeoNode.name = "test"
        
        
        let newText = SCNText(string: "hello", extrusionDepth:1.0)
        newText.font = UIFont (name: "Arial", size: 5)
        newText.firstMaterial!.diffuse.contents = UIColor.whiteColor()
        newText.firstMaterial!.specular.contents = UIColor.whiteColor()
        
        
        cameraText = SCNNode(geometry: newText)
        
        let textureSize = getTextureWidth(UIScreen.mainScreen().bounds.width, hfov: HorizontalFieldOfView)
        imageCache = CollectionImageCache(textureSize: textureSize)
        
        
    
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
        let subSurf = cubeFaceCount
        
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

        
        
        
        sphereGeoNode.position = SCNVector3Make(1.0, 1.0, 0)
        
        
        cameraText.position = SCNVector3Make(1.0, 1.0, 0)
     //   sphereGeoNode.eulerAngles = SCNVector3Make(0, 0, 0)
        
        
        
     //   let pivot = SCNMatrix4MakeTranslation(-(0.0 + 0.1 / 2) * 2 + 1, (0.0 + 0.1 / 2) * 2 - 1, 0)
        
        
     //   var transform = SCNMatrix4Scale(SCNMatrix4MakeRotation(Float(M_PI_2), 1, 0, 0), -1, 1, 1)
     //  transform = SCNMatrix4Mult(sphereGeoNode.transform, transform)
     //   sphereGeoNode.transform = SCNMatrix4Mult(SCNMatrix4Invert(pivot), transform)

        
        scene.rootNode.addChildNode(sphereGeoNode)
        scene.rootNode.addChildNode(cameraText)
        
        
        
        
        
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
        if let item = planes[index] {
            //print("settex \(id) \(index)")
            sync(self) {
                //assert(item.node.geometry!.firstMaterial!.diffuse.contents !== texture) // Don't overwrite textures!
                //assert(item.node.geometry!.firstMaterial!.diffuse.contents === CubeRenderDelegate.BlackTexture) // Don't overwrite textures!
                
                item.node.geometry!.firstMaterial!.diffuse.contents = texture
                
                item.hasTexture = true
                item.requested = false
            }
        }
    }
    
    
    func addMarker(color: UIColor, type: String) {
        
        let planeGeo = SCNPlane(width: 0.1, height: 0.1)
        planeGeo.firstMaterial?.diffuse.contents = UIColor.redColor()
        
        let circleGeo = SCNSphere(radius: 0.01)
        circleGeo.firstMaterial?.diffuse.contents = color
        let markNode = SCNNode(geometry: planeGeo)
        let n = markers.count
        
        markNode.name = type + String(n)
        
        print("camera x: \(self.cameraNode.eulerAngles.x)")
        print("camera y: \(self.cameraNode.eulerAngles.y)")
        print("camera z: \(self.cameraNode.eulerAngles.z)")
        
        markNode.position = sphereGeoNode.position
//        markNode.rotation = self.cameraNode.rotation
        
        markNode.eulerAngles = self.cameraNode.eulerAngles;
        
        print("node x: \(markNode.eulerAngles.x)")
        print("node y: \(markNode.eulerAngles.y)")
        print("node z: \(markNode.eulerAngles.z)")
        
        markNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "story_pin")
        
        
        
        
        scene.rootNode.addChildNode(markNode)
        markers.append(markNode)
        
        delegate!.addVectorAndRotation(markNode.position, rotation: markNode.eulerAngles)
    }
    
    
    func addNodeFromServer(translation: SCNVector3, rotation: SCNVector3){
        
        print("addNodeFromServer(translation: SCNVector3, rotation: SCNVector3)")
        
        let planeGeo = SCNPlane(width: 0.1, height: 0.1)
        planeGeo.firstMaterial?.diffuse.contents = UIColor.redColor()
        
        let circleGeo = SCNSphere(radius: 0.01)
        circleGeo.firstMaterial?.diffuse.contents = UIColor.redColor()
        let markNode = SCNNode(geometry: planeGeo)
        
        markNode.position = translation
        markNode.eulerAngles = rotation
        
        markNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "story_pin")
        
        scene.rootNode.addChildNode(markNode)
        markers.append(markNode)
    }
    
    
    
    
    
    var id: Int = 0
    
    func reset() {
        nodeEnterScene = nil
        nodeLeaveScene = nil
        
        sync(self) {
            for (_, plane) in self.planes {
                //print("resett \(self.id) \(index)")
                plane.node.geometry?.firstMaterial?.diffuse.contents = CubeRenderDelegate.BlackTexture
                plane.visible = false
                plane.hasTexture = false
                plane.requested = false
            }
        }
    }
    
    
    func resetToBlack() {
        nodeEnterScene = nil
        nodeLeaveScene = nil
        
        sync(self) {
            for (_, plane) in self.planes {
                //print("resett \(self.id) \(index)")
                plane.node.geometry?.firstMaterial?.diffuse.contents = CubeRenderDelegate.BlackTexture
                plane.visible = false
                plane.hasTexture = false
            //    plane.requested = false
            }
        }
        
        
        
        
        let cubeImageCache = imageCache.get(0, optographID: "6e5b494d-8e1f-4516-ab95-37165224e323", side: .Left)
        setCubeImageCache(cubeImageCache)
    }
    
    
    
    func setCubeImageCache(cache: CubeImageCache) {
        
        nodeEnterScene = nil
        nodeLeaveScene = nil
        
        reset()
        
        nodeEnterScene = { [weak self] index in
            dispatch_async(queue1) {
                cache.get(index) { [weak self] (texture: SKTexture, index: CubeImageCache.Index) in
                    self!.setTexture(texture, forIndex: index)
         //           Async.main { [weak self] in
          //              self?.loadingStatus.value = .Loaded
          //          }
                }
            }
        }
        
        nodeLeaveScene = { index in
            dispatch_async(queue1) {
                cache.forget(index)
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
    
    func requestAll() {
        willRequestAll = true
    }
    
    func findNextPoint(p0: SCNVector3, direction: SCNVector3) -> SCNVector3{
        
        var x = Float()
        var y = Float()
        var z = Float()
        let t = 1.0 as Float
        
        x = p0.x + t * direction.x
        y = p0.y + t * direction.y
        z = p0.z + t * direction.z
        
        let result = SCNVector3Make(x, y, z)
        return result
        
    }
    
    
    func calculateCameraDirection(cameraNode: SCNNode) -> GLKVector3 {
        
        let x = -cameraNode.rotation.x
        let y = -cameraNode.rotation.y
        let z = -cameraNode.rotation.z
        let w = cameraNode.rotation.w
        
        let cameraRotationMatrix = GLKMatrix3Make(cos(w) + pow(x, 2) * (1 - cos(w)),
                                                  x * y * (1 - cos(w)) - z * sin(w),
                                                  x * z * (1 - cos(w)) + y*sin(w),
                                                  
                                                  y*x*(1-cos(w)) + z*sin(w),
                                                  cos(w) + pow(y, 2) * (1 - cos(w)),
                                                  y*z*(1-cos(w)) - x*sin(w),
                                                  
                                                  z*x*(1 - cos(w)) - y*sin(w),
                                                  z*y*(1 - cos(w)) + x*sin(w),
                                                  cos(w) + pow(z, 2) * ( 1 - cos(w)))
        
        let cameraDirection = GLKMatrix3MultiplyVector3(cameraRotationMatrix, GLKVector3Make(0.0, 0.0, -1.0))
        
        return cameraDirection
        
    }
    
   
    
    
    
    private func request(item: Item, index: CubeImageCache.Index) {
        if !item.visible {
            sync(self) {
                if !item.requested && !item.hasTexture {
                    //print("req \(self.id) \(index)")
                    if let callback = self.nodeEnterScene {
                        item.visible = true
                        item.requested = true
                        callback(index)
                    }
                }
            }
        }
    }
    
    private func forget(item: Item, index: CubeImageCache.Index) {
        if item.visible {
            sync(self) {
                if item.hasTexture {
                    //print("forg \(self.id) \(index)")
                    item.node.geometry!.firstMaterial!.diffuse.contents = CubeRenderDelegate.BlackTexture
                    
                    item.hasTexture = false
                    
                    if let callback = self.nodeLeaveScene {
                        item.visible = false
                        callback(index)
                    }
                }
            }
        }
    }
    
    override func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        super.renderer(aRenderer, updateAtTime: time)
        
        // Use the small camera for debugging.
        // let smallFov = RenderDelegate.getFov(scnView!.bounds.width, height: scnView!.bounds.height, fov: 10)
        // let smallCamera = SCNNode()
       //  smallCamera.camera = RenderDelegate.setupCamera(smallFov)
      //   smallCamera.transform = cameraNode.transform
        
        
        
        let visibleAndAdjacentPlanes = getVisibleAndAdjacentPlanes(self.cameraNode)
        
        
        
        let cameraDirection = calculateCameraDirection(self.cameraNode)
        let camdir = SCNVector3Make(cameraDirection.x, cameraDirection.y, cameraDirection.z)
     //   print("camera direction \(camdir)")
        let nextpoint = findNextPoint(cameraNode.position, direction: SCNVector3Make(cameraDirection.x, cameraDirection.y, cameraDirection.z))
        sphereGeoNode.position = nextpoint
        
        
        cameraText.position = nextpoint
     //   print("next point \(nextpoint)")
        
        
        for marknode in markers {
            
            if self.scnView!.isNodeInsideFrustum(marknode, withPointOfView: self.cameraCrosshair) {
          //      let angle = self.cameraNode.presentationNode.rotation.w * self.cameraNode.presentationNode.rotation.y
           // let elevation = self.cameraNode.rotation.w
          //  var direction = SCNVector3(x: -sin(angle), y: 0, z: -cos(angle))
            //direction = SCNVector3(x: cos(elevation) * direction.x , y: sin(elevation), z: cos(elevation) * direction.z)
           // let eulerangle = sphereGeoNode.position
            let markername = marknode.name
//            print ("marker name \(markername) ")
               
//                if (markername! == "Text Item2") {
////                    print("resetToBlack")
//                  
//                  
//                    
//                }
          delegate!.didEnterFrustrum("", inFrustrum: true)
        }
            else{
                delegate!.didEnterFrustrum("", inFrustrum: false)
            }
        }
 
 
      
        // Use verbose colors for debugging.
      //   planes.values.forEach { $0.node.geometry!.firstMaterial!.diffuse.contents = UIColor.redColor() }
     //    visibleAndAdjacentPlanes.forEach { $0.geometry!.firstMaterial!.diffuse.contents = UIColor.blueColor() }
     //    visiblePlanes.forEach { $0.geometry!.firstMaterial!.diffuse.contents = UIColor.greenColor() }
        
        // TODO - Syncing here is not really fast. It's more like really slow. 
        
        for (index, item) in planes {
            let nowVisible = visibleAndAdjacentPlanes.contains(item.node)
            if nowVisible {
                request(item, index: index)
            } else if autoDispose && !nowVisible {
                forget(item, index: index)
            }
            
            
            
        }
        
        // Forced initialisation of ALL views. We do that past the 
        // above code so faces we look at get priority.
        if willRequestAll {
            for (index, plane) in self.planes {
               request(plane, index: index)
            }
        }
        
    }
    
    private func createPlane(position position: SCNVector3, rotation: SCNVector3, subX: Float, subY: Float, subW: Float) -> SCNNode {
    
         print("[createPlane] \(subX) \(subY) \(subW)   \(position)")
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
    
    deinit {
        logRetain()
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
            
            sphereNode.geometry?.firstMaterial?.diffuse.contents = image
            updateProjectionMatrix(image.size, isSKTexture: false)
        }
    }
    var texture: SKTexture? {
        didSet {
            guard let texture = texture else {
                sphereNode.geometry?.firstMaterial?.diffuse.contents = nil
                return
            }
            
            sphereNode.geometry?.firstMaterial?.diffuse.contents = texture
            updateProjectionMatrix(texture.size(), isSKTexture: true)
        }
    }

    
    override init(rotationMatrixSource: RotationMatrixSource, fov: FieldOfView, cameraOffset: Float) {
        sphereNode = SphereRenderDelegate.createSphere()
        
        super.init(rotationMatrixSource: rotationMatrixSource, fov: fov, cameraOffset: cameraOffset)
        
        scene.rootNode.addChildNode(sphereNode)
    }
    
    private func updateProjectionMatrix(size: CGSize, isSKTexture: Bool) {
        if size.width == size.height {
            // Classic case - quadratic texture
            sphereNode.geometry?.firstMaterial?.diffuse.contents = nil
        } else {
            // Extended case - rectangular texture, need to center
            let ratio = Float((size.width / CGFloat(2)) / size.height)
            
            // Yes, we calculate our transform ourselves.
            // And yes, this matrix is inverted.
            // Texture mapping from 0 to 1
            var transform: SCNMatrix4?;
            
            if isSKTexture {
                transform = SCNMatrix4FromGLKMatrix4(
                    GLKMatrix4Make(
                        1, 0, 0, 0,
                        0, -ratio, 0, 0,
                        0, 0, 1, 0,
                        0, 1 - (1 - ratio) / 2, 0, 1
                    )
                )
            } else {
                transform = SCNMatrix4FromGLKMatrix4(
                    GLKMatrix4Make(
                        1, 0, 0, 0,
                        0, ratio, 0, 0,
                        0, 0, 1, 0,
                        0, (1 - ratio) / 2, 0, 1
                    )
                )
            }
            
            sphereNode.geometry?.firstMaterial?.diffuse.contentsTransform = transform!
            if #available(iOS 9.0, *) {
                sphereNode.geometry?.firstMaterial?.diffuse.wrapS = .ClampToBorder
                sphereNode.geometry?.firstMaterial?.diffuse.wrapT = .ClampToBorder
            } else {
                
            }
            sphereNode.geometry?.firstMaterial?.diffuse.borderColor =  UIColor.blackColor()
            
        }
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
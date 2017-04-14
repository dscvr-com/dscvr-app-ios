//
//  CollectionViewCell.swift
//  Optonaut
//
//  Created by Robert John M. Alkuino on 03/12/2016.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveSwift
import SceneKit
import SpriteKit
import Async

class TouchRotationSource: RotationMatrixSource {
    
    var isTouching = false
    
    // Take care, compared to the webviewer implementation,
    // phi and theta are switched since native apps and the browser use
    // different reference frames.
    var phi: Float = 0
    var theta: Float = Float(-M_PI_2)
    
    // FOV of the scene
    fileprivate let vfov: Float
    fileprivate let hfov: Float
    
    // Damping
    fileprivate var phiDiff: Float = 0
    fileprivate var thetaDiff: Float = 0
    var phiDamp: Float = 0
    var thetaDamp: Float = 0
    var dampFactor: Float = 0.9
    
    fileprivate var touchStartPoint: CGPoint?
    
    fileprivate let sceneWidth: Int
    fileprivate let sceneHeight: Int
    
    // Dependent on optograph format. This values are suitable for
    // Stitcher version <= 7.
    fileprivate let border = Float(M_PI) / Float(6.45)
    fileprivate let minTheta: Float
    fileprivate let maxTheta: Float
    
    init(sceneSize: CGSize, hfov: Float) {
        self.hfov = hfov
        
        sceneWidth = Int(sceneSize.width)
        sceneHeight = Int(sceneSize.height)
        
        vfov = hfov * Float(sceneHeight) / Float(sceneWidth)
        
        maxTheta = -border - (vfov * Float(M_PI) / 180) / 2
        minTheta = Float(-M_PI) - maxTheta
    }
    
    func touchStart(_ point: CGPoint) {
        touchStartPoint = point
        isTouching = true
    }
    
    func touchMove(_ point: CGPoint) {
        if !isTouching {
            return
        }
        
        let x0 = Float(sceneWidth / 2)
        let y0 = Float(sceneHeight / 2)
        let flen = y0 / tan(vfov / 2 * Float(M_PI) / 180)
        
        let startPhi = atan((Float(touchStartPoint!.x) - x0) / flen)
        let startTheta = atan((Float(touchStartPoint!.y) - y0) / flen)
        let endPhi = atan((Float(point.x) - x0) / flen)
        let endTheta = atan((Float(point.y) - y0) / flen)
        
        phiDiff += Float(startPhi - endPhi)
        thetaDiff += Float(startTheta - endTheta)
        
        touchStartPoint = point
    }
    
    func touchEnd() {
        touchStartPoint = nil
        isTouching = false
    }
    
    func reset() {
        phiDiff = 0
        thetaDiff = 0
        phi = 0
        theta = 0
        phiDamp = 0
        thetaDamp = 0
    }
    
    func getRotationMatrix() -> GLKMatrix4 {
        
        if !isTouching {
            // Update from motion and damping
            phiDamp *= dampFactor
            thetaDamp *= dampFactor
            phi += phiDamp
            theta += thetaDamp
        } else {
            // Update from touch
            phi += phiDiff
            theta += thetaDiff
            phiDamp = phiDiff
            thetaDamp = thetaDiff
            phiDiff = 0
            thetaDiff = 0
        }
        
        theta = max(minTheta, min(theta, maxTheta))
        
        return phiThetaToRotationMatrix(phi, theta: theta)
    }
}

class CombinedMotionManager: RotationMatrixSource {
    fileprivate let coreMotionRotationSource: CoreMotionRotationSource
    fileprivate let touchRotationSource: TouchRotationSource
    
    fileprivate var lastCoreMotionRotationMatrix: GLKMatrix4?
    
    init(sceneSize: CGSize, hfov: Float) {
        self.coreMotionRotationSource = CoreMotionRotationSource.Instance
        self.touchRotationSource = TouchRotationSource(sceneSize: sceneSize, hfov: hfov)
    }
    
    init(coreMotionRotationSource: CoreMotionRotationSource, touchRotationSource: TouchRotationSource) {
        self.coreMotionRotationSource = coreMotionRotationSource
        self.touchRotationSource = touchRotationSource
    }
    
    func touchStart(_ point: CGPoint) {
        touchRotationSource.touchStart(point)
    }
    
    func touchMove(_ point: CGPoint) {
        touchRotationSource.touchMove(point)
    }
    
    func touchEnd() {
        touchRotationSource.touchEnd()
    }
    
    func reset() {
        touchRotationSource.reset()
    }
    
    func setDirection(_ direction: Direction) {
        touchRotationSource.phi = direction.phi
        touchRotationSource.theta = direction.theta
    }
    
    func getDirection() -> Direction {
        return (phi: touchRotationSource.phi, theta: touchRotationSource.theta)
    }
    
    func getRotationMatrix() -> GLKMatrix4 {
        
        let coreMotionRotationMatrix = coreMotionRotationSource.getRotationMatrix()
        
        if !touchRotationSource.isTouching {
            // Update from motion and damping
            if let lastCoreMotionRotationMatrix = lastCoreMotionRotationMatrix {
                let diffRotationMatrix = GLKMatrix4Multiply(GLKMatrix4Invert(lastCoreMotionRotationMatrix, nil), coreMotionRotationMatrix)
                
                let diffRotationTheta = atan2(diffRotationMatrix.m21, diffRotationMatrix.m22)
                let diffRotationPhi = atan2(-diffRotationMatrix.m20,
                                            sqrt(diffRotationMatrix.m21 * diffRotationMatrix.m21 +
                                                diffRotationMatrix.m22 * diffRotationMatrix.m22))
                
                touchRotationSource.phi += diffRotationPhi
                touchRotationSource.theta += diffRotationTheta
            }
        }
        
        lastCoreMotionRotationMatrix = coreMotionRotationMatrix
        
        return touchRotationSource.getRotationMatrix()
    }
}

private let queue = DispatchQueue(label: "collection_view_cell", attributes: [])

class OptographCollectionViewCell: UICollectionViewCell {
    
    weak var uiHidden: MutableProperty<Bool>!
    
    // subviews
    fileprivate let topElements = UIView()
    fileprivate let bottomElements = UIView()
    fileprivate let bottomBackgroundView = UIView()
    fileprivate let loadingOverlayView = UIView()
    
    fileprivate var combinedMotionManager: CombinedMotionManager!
    fileprivate var renderDelegate: CubeRenderDelegate!
    fileprivate var scnView: SCNView!
    
    fileprivate let loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    fileprivate var touchStart: CGPoint?
    
    fileprivate enum LoadingStatus { case nothing, preview, loaded }
    fileprivate let loadingStatus = MutableProperty<LoadingStatus>(.nothing)
    
    var direction: Direction {
        set(direction) {
            combinedMotionManager.setDirection(direction)
        }
        get {
            return combinedMotionManager.getDirection()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .black
        
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: contentView.frame, options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.openGLES2.rawValue])
        } else {
            scnView = SCNView(frame: contentView.frame)
        }
        
        let hfov: Float = 35
        
        combinedMotionManager = CombinedMotionManager(sceneSize: scnView.frame.size, hfov: hfov)
        
        renderDelegate = CubeRenderDelegate(rotationMatrixSource: combinedMotionManager, width: scnView.frame.width, height: scnView.frame.height, fov: Double(hfov), cubeFaceCount: 2, autoDispose: true)
        renderDelegate.scnView = scnView
        
        renderDelegate.scnView = scnView
        
        scnView.scene = renderDelegate.scene
        scnView.delegate = renderDelegate
        scnView.backgroundColor = .clear
        scnView.isHidden = false
        contentView.addSubview(scnView)
        
        loadingOverlayView.backgroundColor = .black
        loadingOverlayView.frame = contentView.frame
        loadingOverlayView.rac_hidden <~ loadingStatus.producer.equalsTo(value: .nothing).map(negate)
        contentView.addSubview(loadingOverlayView)
        
        loadingIndicatorView.frame = contentView.frame
        loadingIndicatorView.rac_animating <~ loadingStatus.producer.equalsTo(value: .nothing)
        contentView.addSubview(loadingIndicatorView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        var point = touches.first!.location(in: contentView)
        touchStart = point
        
        if !uiHidden.value {
            point.y = 0
        }
        
        if touches.count == 1 {
            combinedMotionManager.touchStart(point)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        var point = touches.first!.location(in: contentView)
        
        if !uiHidden.value {
            if abs(point.x - touchStart!.x) > 20 {
                uiHidden.value = true
                combinedMotionManager.touchStart(point)
                return
            }
            
            point.y = 0
        }
        
        combinedMotionManager.touchMove(point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let distance = touchStart!.distanceTo(touches.first!.location(in: self))
        if distance < 10 {
            uiHidden.value = !uiHidden.value
        }
        super.touchesEnded(touches, with: event)
        if touches.count == 1 {
            combinedMotionManager.touchEnd()
        }
    }
    
    var id: Int = 0 {
        didSet {
            renderDelegate.id = id
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        super.touchesCancelled(touches!, with: event)
        if let touches = touches, touches.count == 1 {
            combinedMotionManager.touchEnd()
        }
    }
    
    func getVisibleAndAdjacentPlaneIndices(_ direction: Direction) -> [CubeImageCache.Index] {
        let rotation = phiThetaToRotationMatrix(direction.phi, theta: direction.theta)
        return renderDelegate.getVisibleAndAdjacentPlaneIndicesFromRotationMatrix(rotation)
    }
    
    func setCubeImageCache(_ cache: CubeImageCache) {
        
        renderDelegate.nodeEnterScene = nil
        renderDelegate.nodeLeaveScene = nil
        
        renderDelegate.reset()
        
        renderDelegate.nodeEnterScene = { [weak self] index in
            queue.async {
                cache.get(index) { [weak self] (texture: SKTexture, index: CubeImageCache.Index) in
                    self?.renderDelegate.setTexture(texture, forIndex: index)
                    Async.main { [weak self] in
                        self?.loadingStatus.value = .loaded
                    }
                }
            }
        }
        
        renderDelegate.nodeLeaveScene = { index in
            queue.async {
                cache.forget(index)
            }
        }
    }
    
    func willDisplay() {
        scnView.isPlaying = UIDevice.current.deviceType != .simulator
    }
    
    func didEndDisplay() {
        scnView.isPlaying = false
        combinedMotionManager.reset()
        loadingStatus.value = .nothing
        renderDelegate.reset()
    }
    
    func forgetTextures() {
        renderDelegate.reset()
    }
    
    deinit {
        logRetain()
    }
}

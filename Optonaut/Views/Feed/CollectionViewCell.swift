//
//  CollectionViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SceneKit
import SpriteKit
import Async

class NewCombinedMotionManager: RotationMatrixSource {
    private var horizontalOffset: Float = 0
    private let coreMotionRotationSource: CoreMotionRotationSource
    
    private var lastCoreMotionRotationMatrix: GLKMatrix4?
    
    // Take care, compared to the webviewer implementation,
    // phi and theta are switched since native apps and the browser use
    // different reference frames.
    private var phi: Float = 0
    private var theta: Float = Float(-M_PI_2)
    
    // Damping
    private var phiDiff: Float = 0
    private var thetaDiff: Float = 0
    private var phiDamp: Float = 0
    private var thetaDamp: Float = 0
    private let dampFactor: Float = 0.9
    
    private var isTouching = false
    private var touchStartPoint: CGPoint?
    
    private let sceneWidth: Int
    private let sceneHeight: Int
    
    // FOV of the scene
    private let vfov: Float
    private let hfov: Float
    
    // Dependent on optograph format. This values are suitable for
    // Stitcher version <= 7.
    private let border = Float(M_PI) / Float(6.45)
    private let minTheta: Float
    private let maxTheta: Float
    
    init(coreMotionRotationSource: CoreMotionRotationSource, sceneSize: CGSize, vfov: Float) {
        self.coreMotionRotationSource = coreMotionRotationSource
        self.vfov = vfov
        
        sceneWidth = Int(sceneSize.width)
        sceneHeight = Int(sceneSize.height)
            
        hfov = vfov * Float(sceneHeight) / Float(sceneWidth)
        
        maxTheta = -border - (hfov * Float(M_PI) / 180) / 2
        minTheta = Float(-M_PI) - maxTheta
    }
    
    func touchStart(point: CGPoint) {
        touchStartPoint = point
        isTouching = true
    }
    
    func touchMove(point: CGPoint) {
        let x0 = Float(sceneWidth / 2)
        let y0 = Float(sceneHeight / 2)
        let flen = y0 / tan(hfov / 2 * Float(M_PI) / 180)
        
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
        
        let coreMotionRotationMatrix = coreMotionRotationSource.getRotationMatrix()
        
        if !isTouching {
            // Update from motion and damping
            if let lastCoreMotionRotationMatrix = lastCoreMotionRotationMatrix {
                let diffRotationMatrix = GLKMatrix4Multiply(GLKMatrix4Invert(lastCoreMotionRotationMatrix, nil), coreMotionRotationMatrix)
                
                let diffRotationTheta = atan2(diffRotationMatrix.m21, diffRotationMatrix.m22)
                let diffRotationPhi = atan2(-diffRotationMatrix.m20,
                                            sqrt(diffRotationMatrix.m21 * diffRotationMatrix.m21 +
                                                diffRotationMatrix.m22 * diffRotationMatrix.m22))
                
                phi += diffRotationPhi
                theta += diffRotationTheta
            }
            
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
        
        lastCoreMotionRotationMatrix = coreMotionRotationMatrix
        
        return GLKMatrix4Multiply(GLKMatrix4MakeZRotation(-phi), GLKMatrix4MakeXRotation(-theta))
    }
}

class CollectionViewCell: UICollectionViewCell {
    
    weak var uiHidden: MutableProperty<Bool>!
    
    private var combinedMotionManager: NewCombinedMotionManager!
    
    private let vfov: Float = 45
    
    // subviews
    private let topElements = UIView()
    private let bottomElements = UIView()
    private let bottomBackgroundView = UIView()
    private let loadingOverlayView = UIView()
    
    private var renderDelegate: StereoRenderDelegate!
    private var scnView: SCNView!
    
    private var touchStart: CGPoint?
    
    private let isLoading = MutableProperty<Bool>(true)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .blackColor()
        
        scnView = SCNView(frame: contentView.frame)
    
        combinedMotionManager = NewCombinedMotionManager(coreMotionRotationSource: CoreMotionRotationSource.Instance, sceneSize: CGSize(width: scnView.frame.width, height: scnView.frame.height), vfov: vfov)
    
        renderDelegate = StereoRenderDelegate(rotationMatrixSource: combinedMotionManager, width: scnView.frame.width, height: scnView.frame.height, fov: Double(vfov))
        
        scnView.scene = renderDelegate.scene
        scnView.delegate = renderDelegate
        scnView.backgroundColor = .clearColor()
        contentView.addSubview(scnView)
        
        loadingOverlayView.backgroundColor = .blackColor()
        loadingOverlayView.frame = contentView.frame
        loadingOverlayView.rac_hidden <~ isLoading.producer.map(negate)
        contentView.addSubview(loadingOverlayView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        touchStart = touches.first!.locationInView(self)
        super.touchesBegan(touches, withEvent: event)
        if uiHidden.value && touches.count == 1 {
            combinedMotionManager.touchStart(touches.first!.locationInView(contentView))
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        if uiHidden.value {
            combinedMotionManager.touchMove(touches.first!.locationInView(contentView))
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let distance = touchStart!.distanceTo(touches.first!.locationInView(self))
        if distance < 10 {
            toggleUI()
        }
        super.touchesEnded(touches, withEvent: event)
        if touches.count == 1 {
            combinedMotionManager.touchEnd()
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        if let touches = touches where touches.count == 1 {
            combinedMotionManager.touchEnd()
        }
    }
    
    func reset() {
        combinedMotionManager.reset()
        isLoading.value = true
    }
    
    func setImage(texture: SKTexture) {
        if renderDelegate.texture != texture {
            renderDelegate.image = nil
            renderDelegate.texture = texture
            scnView.prepareObject(renderDelegate!.sphereNode, shouldAbortBlock: nil)
        }
        Async.main { [weak self] in
            self?.isLoading.value = false
        }
    }
    
    func willDisplay() {
        scnView.playing = UIDevice.currentDevice().deviceType != .Simulator
    }
    
    func didEndDisplay() {
        renderDelegate.image = nil
        scnView.playing = false
    }
    
    private func toggleUI() {
        uiHidden.value = !uiHidden.value
    }
    
}

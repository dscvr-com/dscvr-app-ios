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
    
    weak var navigationController: NavigationController?
    let viewModel = CollectionViewCellModel()
    
    private var combinedMotionManager: NewCombinedMotionManager!
    
    private let vfov: Float = 45
    
    // subviews
    private let topElements = UIView()
    private let bottomElements = UIView()
    private let bottomBackgroundView = UIView()
    private let bottomGradient = CAGradientLayer()
    private let avatarImageView = UIImageView()
    private let personNameView = UILabel()
    private let locationTextView = UILabel()
    private let searchButtonView = UIButton()
    private let optionsButtonView = UIButton()
    private let likeButtonView = UIButton()
    private let likeCountView = UILabel()
    private let dateView = UILabel()
    private let textView = UILabel()
    private let loadingOverlayView = UIView()
    
    private var renderDelegate: StereoRenderDelegate!
    private var scnView: SCNView!
    
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
        loadingOverlayView.rac_hidden <~ viewModel.isLoading.producer.map(negate)
        contentView.addSubview(loadingOverlayView)
        
        topElements.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: 122)
        
        let topGradient = CAGradientLayer()
        topGradient.frame = topElements.frame
        topGradient.colors = [UIColor.blackColor().alpha(0.5).CGColor, UIColor.clearColor().CGColor]
        topElements.layer.addSublayer(topGradient)
        
        avatarImageView.layer.cornerRadius = 21.5
        avatarImageView.layer.borderColor = UIColor.whiteColor().CGColor
        avatarImageView.layer.borderWidth = 1.5
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        topElements.addSubview(avatarImageView)
        
        personNameView.font = UIFont.displayOfSize(15, withType: .Regular)
        personNameView.textColor = .whiteColor()
        topElements.addSubview(personNameView)
        
        searchButtonView.titleLabel?.font = UIFont.iconOfSize(28)
        searchButtonView.setTitle(String.iconWithName(.Search), forState: .Normal)
        topElements.addSubview(searchButtonView)
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(28)
        optionsButtonView.setTitle(String.iconWithName(.More_Vert), forState: .Normal)
        topElements.addSubview(optionsButtonView)
        
        locationTextView.font = UIFont.displayOfSize(11, withType: .Light)
        locationTextView.textColor = .whiteColor()
        topElements.addSubview(locationTextView)
        
        topElements.rac_hidden <~ viewModel.uiHidden
        contentView.addSubview(topElements)
        
        bottomGradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().alpha(0.5).CGColor]
        bottomElements.layer.addSublayer(bottomGradient)
        
        likeButtonView.layer.cornerRadius = 14
        likeButtonView.clipsToBounds = true
        likeButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleLike"))
        likeButtonView.setTitle(String.iconWithName(.HeartFilled), forState: .Normal)
        bottomElements.addSubview(likeButtonView)
        
        likeCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        likeCountView.textColor = .whiteColor()
        bottomElements.addSubview(likeCountView)
        
        likeCountView.rac_text <~ viewModel.likeCount.producer.map { "\($0)" }
        
        viewModel.liked.producer.startWithNext { [weak self] liked in
            if let strongSelf = self {
                if liked {
                    strongSelf.likeButtonView.anchorInCorner(.TopLeft, xPad: 18, yPad: 10, width: 28, height: 28)
                    strongSelf.likeButtonView.backgroundColor = .Accent
                    strongSelf.likeButtonView.titleLabel?.font = UIFont.iconOfSize(12)
                } else {
                    strongSelf.likeButtonView.anchorInCorner(.TopLeft, xPad: 18, yPad: 10, width: 20, height: 28)
                    strongSelf.likeButtonView.backgroundColor = .clearColor()
                    strongSelf.likeButtonView.titleLabel?.font = UIFont.iconOfSize(21)
                }
                strongSelf.likeCountView.align(.ToTheRightCentered, relativeTo: strongSelf.likeButtonView, padding: 8, width: 40, height: 13)
            }
        }
        
        dateView.font = UIFont.displayOfSize(11, withType: .Thin)
        dateView.textColor = .whiteColor()
        dateView.textAlignment = .Right
        bottomElements.addSubview(dateView)
        
        textView.font = UIFont.displayOfSize(13, withType: .Light)
        textView.textColor = .whiteColor()
        textView.userInteractionEnabled = true
        bottomElements.addSubview(textView)
        
        viewModel.textToggled.producer.startWithNext { [weak self] toggled in
            if let strongSelf = self, text = strongSelf.viewModel.optograph?.text {
                let textHeight = calcTextHeight(text, withWidth: strongSelf.contentView.frame.width - 36, andFont: UIFont.displayOfSize(13, withType: .Light))
                let displayedTextHeight = toggled && textHeight > 16 ? textHeight : 15
                let bottomHeight: CGFloat = 50 + (text.isEmpty ? 0 : displayedTextHeight + 11)
                
                UIView.setAnimationCurve(.EaseInOut)
                UIView.animateWithDuration(0.3) {
                    strongSelf.bottomElements.frame = CGRect(x: 0, y: strongSelf.contentView.frame.height - 108 - bottomHeight, width: strongSelf.contentView.frame.width, height: bottomHeight)
                }
                
                strongSelf.textView.anchorInCorner(.BottomLeft, xPad: 18, yPad: 16, width: strongSelf.contentView.frame.width - 36, height: displayedTextHeight)
                
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.3)
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
                strongSelf.bottomGradient.frame = CGRect(x: 0, y: 0, width: strongSelf.contentView.frame.width, height: bottomHeight)
                CATransaction.commit()
                
                strongSelf.textView.numberOfLines = toggled ? 0 : 1
            }
        }
        
        bottomElements.clipsToBounds = true
        bottomElements.rac_hidden <~ viewModel.uiHidden
        bottomElements.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleText"))
        contentView.addSubview(bottomElements)
        
        bottomBackgroundView.frame = CGRect(x: 0, y: contentView.frame.height - 108, width: contentView.frame.width, height: 108)
        bottomBackgroundView.backgroundColor = UIColor.blackColor().alpha(0.5)
        bottomBackgroundView.rac_hidden <~ viewModel.uiHidden
        contentView.addSubview(bottomBackgroundView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        avatarImageView.anchorInCorner(.TopLeft, xPad: 16.5, yPad: 28.5, width: 43, height: 43)
        searchButtonView.anchorInCorner(.TopRight, xPad: 52, yPad: 37, width: 24, height: 24)
        optionsButtonView.anchorInCorner(.TopRight, xPad: 14, yPad: 37, width: 24, height: 24)
        dateView.anchorInCorner(.TopRight, xPad: 18, yPad: 17, width: 70, height: 13)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        if viewModel.uiHidden.value && touches.count == 1 {
            combinedMotionManager.touchStart(touches.first!.locationInView(contentView))
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        if viewModel.uiHidden.value {
            combinedMotionManager.touchMove(touches.first!.locationInView(contentView))
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
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
    
    func reset(optograph: Optograph) {
        combinedMotionManager.reset()
        
        viewModel.bind(optograph)
        
        avatarImageView.kf_setImageWithURL(NSURL(string: ImageURL(optograph.person.avatarAssetID, width: 40, height: 40))!)
        personNameView.text = optograph.person.displayName
        locationTextView.text = optograph.location?.text
        dateView.text = optograph.createdAt.longDescription
        textView.text = optograph.text
        
        if let location = optograph.location {
            locationTextView.text = "\(location.text), \(location.country)"
            personNameView.anchorInCorner(.TopLeft, xPad: 69, yPad: 34, width: 100, height: 18)
            locationTextView.anchorInCorner(.TopLeft, xPad: 69, yPad: 53, width: 200, height: 13)
        } else {
            personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
        }
    }
    
    func setImage(image: SKTexture) {
        renderDelegate.image = image
        Async.main { [weak self] in
            self?.viewModel.isLoading.value = false
        }
    }
    
    func willDisplay() {
        scnView.playing = UIDevice.currentDevice().deviceType != .Simulator
    }
    
    func didEndDisplay() {
        renderDelegate.image = nil
        scnView.playing = false
    }
    
    func toggleUI() {
        viewModel.uiHidden.value = !viewModel.uiHidden.value
    }
    
    func toggleText() {
        viewModel.textToggled.value = !viewModel.textToggled.value
    }
    
    func toggleLike() {
        viewModel.toggleLike()
    }
    
    func pushProfile() {
        navigationController?.pushViewController(ProfileTableViewController(personID: viewModel.optograph!.person.ID), animated: true)
    }
    
}
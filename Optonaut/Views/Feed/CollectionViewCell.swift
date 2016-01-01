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

class NewCombinedMotionManager: RotationMatrixSource {
    private var horizontalOffset: Float = 0
    private let coreMotionRotationSource: CoreMotionRotationSource
    
    private var lastCoreMotionRotationMatrix: GLKMatrix4?
    
    private var phiDiff: Float = 0
    private var phi: Float = 0
    private var thetaDiff: Float = 0
    private var theta: Float = 0
    
    private var isTouching = false
    private var touchStartPoint: CGPoint?
    
    init(coreMotionRotationSource: CoreMotionRotationSource) {
        self.coreMotionRotationSource = coreMotionRotationSource
    }
    
    func touchStart(point: CGPoint) {
        touchStartPoint = point
        isTouching = true
    }
    
    func touchMove(point: CGPoint) {
        let x0 = UIScreen.mainScreen().bounds.width / 2
        let y0 = UIScreen.mainScreen().bounds.height / 2
        let hfov: CGFloat = 65
        let flen = x0 / tan(hfov / 2 * CGFloat(M_PI) / 180)
        
        let startPhi = atan((touchStartPoint!.x - x0) / flen)
        let startTheta = atan((touchStartPoint!.y - y0) / flen)
        let endPhi = atan((point.x - x0) / flen)
        let endTheta = atan((point.y - y0) / flen)
        
        phiDiff = Float(startPhi - endPhi)
        phi += phiDiff
        
        thetaDiff = Float(startTheta - endTheta)
        theta += thetaDiff
        
        touchStartPoint = point
    }
    
    func touchEnd() {
        touchStartPoint = nil
        isTouching = false
    }
    
    func getRotationMatrix() -> GLKMatrix4 {
        
        let coreMotionRotationMatrix = coreMotionRotationSource.getRotationMatrix()
        if !isTouching {
            if let lastCoreMotionRotationMatrix = lastCoreMotionRotationMatrix {
                let diffRotationMatrix = GLKMatrix4Multiply(GLKMatrix4Invert(lastCoreMotionRotationMatrix, nil), coreMotionRotationMatrix)
                
                let diffRotationTheta = atan2(diffRotationMatrix.m21, diffRotationMatrix.m22)
                let diffRotationPhi = atan2(-diffRotationMatrix.m20,
                                            sqrt(diffRotationMatrix.m21 * diffRotationMatrix.m21 +
                                                diffRotationMatrix.m22 * diffRotationMatrix.m22))
                
                phi += diffRotationPhi
                theta += diffRotationTheta
            }
        }
        
        //print("Phi: \(phi), Theta: \(theta)")
        
        lastCoreMotionRotationMatrix = coreMotionRotationMatrix
        
        return GLKMatrix4Multiply(GLKMatrix4MakeZRotation(-phi), GLKMatrix4MakeXRotation(-theta))
    }
}

class CollectionViewCell: UICollectionViewCell {
    
    weak var navigationController: NavigationController?
    let viewModel = CollectionViewCellModel()
    
    private let combinedMotionManager = NewCombinedMotionManager(coreMotionRotationSource: CoreMotionRotationSource.Instance)
    
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
    
    private var renderDelegate: StereoRenderDelegate!
    private var scnView: SCNView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .blackColor()
        
        scnView = SCNView(frame: contentView.frame)
        
        renderDelegate = StereoRenderDelegate(rotationMatrixSource: combinedMotionManager, width: scnView.frame.width, height: scnView.frame.height, fov: 65)
        
        scnView.scene = renderDelegate.scene
        scnView.delegate = renderDelegate
        scnView.backgroundColor = .clearColor()
        
        contentView.addSubview(scnView)
        
        topElements.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: 122)
        
        let topGradient = CAGradientLayer()
        topGradient.frame = topElements.frame
        topGradient.colors = [UIColor.blackColor().alpha(0.5).CGColor, UIColor.clearColor().CGColor]
        topElements.layer.addSublayer(topGradient)
        
        avatarImageView.layer.cornerRadius = 21.5
        avatarImageView.layer.borderColor = UIColor.whiteColor().CGColor
        avatarImageView.layer.borderWidth = 1.5
        avatarImageView.clipsToBounds = true
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
        textView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleText"))
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
    
    func bindViewModel(optograph: Optograph) {
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
    }
    
    func willDisplay() {
        scnView.playing = true
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
    
}
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

class TouchRotationSource: RotationMatrixSource {
    
    var isTouching = false
    
    // Take care, compared to the webviewer implementation,
    // phi and theta are switched since native apps and the browser use
    // different reference frames.
    var phi: Float = 0
    var theta: Float = Float(-M_PI_2)
    
    // FOV of the scene
    private let vfov: Float
    private let hfov: Float
    
    // Damping
    private var phiDiff: Float = 0
    private var thetaDiff: Float = 0
    var phiDamp: Float = 0
    var thetaDamp: Float = 0
    var dampFactor: Float = 0.9
    
    private var touchStartPoint: CGPoint?
    
    private let sceneWidth: Int
    private let sceneHeight: Int
    
    // Dependent on optograph format. This values are suitable for
    // Stitcher version <= 7.
    private let border = Float(M_PI) / Float(6.45)
    private let minTheta: Float
    private let maxTheta: Float
    
    init(sceneSize: CGSize, hfov: Float) {
        self.hfov = hfov
        
        sceneWidth = Int(sceneSize.width)
        sceneHeight = Int(sceneSize.height)
            
        vfov = hfov * Float(sceneHeight) / Float(sceneWidth)
        
        maxTheta = -border - (vfov * Float(M_PI) / 180) / 2
        minTheta = Float(-M_PI) - maxTheta
    }
    
    func touchStart(point: CGPoint) {
        touchStartPoint = point
        isTouching = true
    }
    
    func touchMove(point: CGPoint) {
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
    private let coreMotionRotationSource: CoreMotionRotationSource
    private let touchRotationSource: TouchRotationSource
    
    private var lastCoreMotionRotationMatrix: GLKMatrix4?
    
    init(sceneSize: CGSize, hfov: Float) {
        self.coreMotionRotationSource = CoreMotionRotationSource.Instance
        self.touchRotationSource = TouchRotationSource(sceneSize: sceneSize, hfov: hfov)
    }
    
    init(coreMotionRotationSource: CoreMotionRotationSource, touchRotationSource: TouchRotationSource) {
        self.coreMotionRotationSource = coreMotionRotationSource
        self.touchRotationSource = touchRotationSource
    }
    
    func touchStart(point: CGPoint) {
        touchRotationSource.touchStart(point)
    }
    
    func touchMove(point: CGPoint) {
        touchRotationSource.touchMove(point)
    }
    
    func touchEnd() {
        touchRotationSource.touchEnd()
    }
    
    func reset() {
        touchRotationSource.reset()
    }
    
    func setDirection(direction: Direction) {
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
    
private let queue = dispatch_queue_create("collection_view_cell", DISPATCH_QUEUE_SERIAL)

private class OverlayViewModel {
    
    let likeCount = MutableProperty<Int>(0)
    let liked = MutableProperty<Bool>(false)
    let textToggled = MutableProperty<Bool>(false)
    
    enum UploadStatus { case Offline, Uploading, Uploaded }
    let uploadStatus = MutableProperty<UploadStatus>(.Uploaded)
    
    var optographBox: ModelBox<Optograph>!
    
    var optograph: Optograph!
    
    func bind(optographID: UUID) {
        
        optographBox = Models.optographs[optographID]!
        
        textToggled.value = false
        
        optographBox.producer.startWithNext { [weak self] optograph in
            self?.likeCount.value = optograph.starsCount
            self?.liked.value = optograph.isStarred
            
            if optograph.isPublished {
                self?.uploadStatus.value = .Uploaded
            } else if optograph.isUploading {
                self?.uploadStatus.value = .Uploading
            } else {
                self?.uploadStatus.value = .Offline
            }
        }
    }
    
    func toggleLike() {
        let starredBefore = liked.value
        let starsCountBefore = likeCount.value
        
        let optograph = optographBox.model
        
        SignalProducer<Bool, ApiError>(value: starredBefore)
            .flatMap(.Latest) { followedBefore in
                starredBefore
                    ? ApiService<EmptyResponse>.delete("optographs/\(optograph.ID)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(optograph.ID)/star", parameters: nil)
            }
            .on(
                started: { [weak self] in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.isStarred = !starredBefore
                        box.model.starsCount += starredBefore ? -1 : 1
                    }
                },
                failed: { [weak self] _ in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.isStarred = starredBefore
                        box.model.starsCount = starsCountBefore
                    }
                }
            )
            .start()
    }
    
    func upload() {
        if !optographBox.model.isOnServer {
            let optograph = optographBox.model
            
            optographBox.update { box in
                box.model.isUploading = true
            }
            
            let postParameters = [
                "id": optograph.ID,
                "stitcher_version": StitcherVersion,
                "created_at": optograph.createdAt.toRFC3339String(),
                ]
            
            var putParameters: [String: AnyObject] = [
                "text": optograph.text,
                "is_private": optograph.isPrivate,
                "post_facebook": optograph.postFacebook,
                "post_twitter": optograph.postTwitter,
                "direction_phi": optograph.directionPhi,
                "direction_theta": optograph.directionTheta,
                ]
            if let locationID = optograph.locationID, location = Models.locations[locationID]?.model {
                putParameters["location"] = [
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                    "text": location.text,
                    "country": location.country,
                    "country_short": location.countryShort,
                    "place": location.place,
                    "region": location.region,
                    "poi": location.POI,
                ]
            }
            
            SignalProducer<Bool, ApiError>(value: !optographBox.model.shareAlias.isEmpty)
                .flatMap(.Latest) { alreadyPosted -> SignalProducer<Void, ApiError> in
                    if alreadyPosted {
                        return SignalProducer(value: ())
                    } else {
                        return ApiService<OptographApiModel>.post("optographs", parameters: postParameters)
                            .on(next: { [weak self] optograph in
                                self?.optographBox.insertOrUpdate { box in
                                    box.model.shareAlias = optograph.shareAlias
                                }
                                })
                            .map { _ in () }
                    }
                }
                .flatMap(.Latest) {
                    ApiService<EmptyResponse>.put("optographs/\(optograph.ID)", parameters: putParameters)
                        .on(failed: { [weak self] _ in
                            self?.optographBox.update { box in
                                box.model.isUploading = false
                            }
                            })
                }
                .on(next: { [weak self] optograph in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.isOnServer = true
                    }
                    })
                .startWithCompleted {
                    PipelineService.checkUploading()
            }
            
            
        } else {
            optographBox.insertOrUpdate { box in
                box.model.shouldBePublished = true
                box.model.isUploading = true
            }
            
            PipelineService.checkUploading()
        }
        
    }
}

class OptographCollectionViewCell: UICollectionViewCell {
    
    weak var uiHidden: MutableProperty<Bool>!
    
    private let viewModel = OverlayViewModel()
    weak var navigationController: NavigationController?
    
    weak var parentViewController: UIViewController?
    // subviews
    private let topElements = UIView()
    private let bottomElements = UIView()
    private let bottomBackgroundView = UIView()
    private let loadingOverlayView = UIView()
    
    private var combinedMotionManager: CombinedMotionManager!
    private var renderDelegate: CubeRenderDelegate!
    private var scnView: SCNView!
    
    private let loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    
    private var touchStart: CGPoint?
    
    private enum LoadingStatus { case Nothing, Preview, Loaded }
    private let loadingStatus = MutableProperty<LoadingStatus>(.Nothing)
    
    private let whiteBackground = UIView()
    private let avatarImageView = UIImageView()
    private let locationTextView = UILabel()
    private let likeCountView = UILabel()
    private let personNameView = BoundingLabel()
    private let optionsButtonView = BoundingButton()
    private let likeButtonView = BoundingButton()
    private let blackSpace = UIView()
    let shareImageAsset = UIImageView()
    private let bouncingButton = UIButton()
    
    var optoId:UUID = ""
    
    var deleteCallback: (() -> ())?
    
    var direction: Direction {
        set(direction) {
            combinedMotionManager.setDirection(direction)
        }
        get {
            return combinedMotionManager.getDirection()
        }
    }
    var hiddenGestureRecognizer:UISwipeGestureRecognizer!
    
    dynamic private func pushProfile() {
        
        let detailsViewController = DetailsTableViewController(optographId:optoId)
        detailsViewController.cellIndexpath = id
        self.navigationController!.pushViewController(detailsViewController, animated: true)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = UIColor(hex:0xffbc00)
        
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: contentView.frame, options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
        } else {
            scnView = SCNView(frame: contentView.frame)
        }
        
        let hfov: Float = 35
        
    
        combinedMotionManager = CombinedMotionManager(sceneSize: scnView.frame.size, hfov: hfov)
    
        renderDelegate = CubeRenderDelegate(rotationMatrixSource: combinedMotionManager, width: scnView.frame.width, height: scnView.frame.height, fov: Double(hfov), cubeFaceCount: 2, autoDispose: true)
        renderDelegate.scnView = scnView
        
        scnView.scene = renderDelegate.scene
        scnView.delegate = renderDelegate
        scnView.backgroundColor = .clearColor()
        scnView.hidden = false
        scnView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OptographCollectionViewCell.pushProfile)))
        contentView.addSubview(scnView)
        
        loadingOverlayView.backgroundColor = .blackColor()
        loadingOverlayView.frame = contentView.frame
        loadingOverlayView.rac_hidden <~ loadingStatus.producer.equalsTo(.Nothing).map(negate)
        contentView.addSubview(loadingOverlayView)
        
        loadingIndicatorView.frame = contentView.frame
        loadingIndicatorView.rac_animating <~ loadingStatus.producer.equalsTo(.Nothing)
        contentView.addSubview(loadingIndicatorView)
        
        whiteBackground.backgroundColor = UIColor.blackColor().alpha(0.60)
        contentView.addSubview(whiteBackground)
        
        blackSpace.backgroundColor = UIColor.blackColor()
        contentView.addSubview(blackSpace)
        
        avatarImageView.layer.cornerRadius = 23.5
        avatarImageView.backgroundColor = .whiteColor()
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        //avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OptographCollectionViewCell.pushProfile)))
        whiteBackground.addSubview(avatarImageView)
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(21)
        optionsButtonView.setImage(UIImage(named:"feeds_option_icn"), forState: .Normal)
        optionsButtonView.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        optionsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didTapOptions)))
        whiteBackground.addSubview(optionsButtonView)
        
        personNameView.font = UIFont.displayOfSize(15, withType: .Regular)
        personNameView.textColor = UIColor(0xffbc00)
        personNameView.userInteractionEnabled = true
        //personNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OverlayView.pushProfile)))
        whiteBackground.addSubview(personNameView)
        
        //likeButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector()))
        likeButtonView.addTarget(self, action: #selector(self.toggleStar), forControlEvents: [.TouchDown])
        likeButtonView.setImage(UIImage(named:"user_unlike_icn"), forState: .Normal)
        whiteBackground.addSubview(likeButtonView)
        
        locationTextView.font = UIFont.displayOfSize(11, withType: .Light)
        locationTextView.textColor = UIColor.whiteColor()
        whiteBackground.addSubview(locationTextView)
        
        likeCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        likeCountView.textColor = .whiteColor()
        likeCountView.textAlignment = .Right
        whiteBackground.addSubview(likeCountView)

        shareImageAsset.layer.cornerRadius = avatarImageView.frame.size.width / 2
        shareImageAsset.image = UIImage(named: "share_hidden_icn")
        contentView.addSubview(shareImageAsset)
        
        hiddenGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(OptographCollectionViewCell.handlePan(_:)))
        hiddenGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Right
        hiddenGestureRecognizer.cancelsTouchesInView = false;
        scnView.addGestureRecognizer(hiddenGestureRecognizer)
        
        bouncingButton.addTarget(self, action: #selector(self.bouncingCell), forControlEvents:.TouchUpInside)
        bouncingButton.setImage(UIImage(named: "bouncing_button")!, forState: .Normal)
        scnView.addSubview(bouncingButton)
        
        contentView.bringSubviewToFront(scnView)
        contentView.bringSubviewToFront(whiteBackground)
        contentView.bringSubviewToFront(blackSpace)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        blackSpace.anchorAndFillEdge(.Bottom, xPad: 0, yPad: 0, otherSize: 20)
        whiteBackground.align(.AboveMatchingLeft, relativeTo: blackSpace, padding: 0, width: contentView.frame.width , height: 66)
        avatarImageView.anchorToEdge(.Left, padding: 10, width: 47, height: 47)
        personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
        likeButtonView.anchorInCorner(.BottomRight, xPad: 16, yPad: 21, width: 24, height: 28)
        likeCountView.align(.ToTheLeftCentered, relativeTo: likeButtonView, padding: 10, width:40, height: 13)
        optionsButtonView.align(.ToTheLeftCentered, relativeTo: likeCountView, padding: 15, width:24, height: 24)
        shareImageAsset.anchorToEdge(.Left, padding: 10, width: avatarImageView.frame.size.width, height: avatarImageView.frame.size.width)
        bouncingButton.anchorToEdge(.Left, padding: 10, width: avatarImageView.frame.size.width, height: avatarImageView.frame.size.width)
    }
    
    func bouncingCell() {
        UIView.animateWithDuration(0.1, animations: {
            self.scnView.frame.origin.x = 60
            }, completion:{ finished in
                UIView.animateWithDuration(0.1, animations: {
                    self.scnView.frame.origin.x = 0
                    }, completion:{ finished in
                        UIView.animateWithDuration(0.1, animations: {
                            self.scnView.frame.origin.x = 35
                            }, completion:{ finished in
                                UIView.animateWithDuration(0.1, animations: {
                                    self.scnView.frame.origin.x = 0
                                    }, completion:{ finished in
                                        UIView.animateWithDuration(0.1, animations: {
                                            self.scnView.frame.origin.x = 15
                                            }, completion:{ finished in
                                                UIView.animateWithDuration(0.1, animations: {
                                                    self.scnView.frame.origin.x = 5
                                                    }, completion:{ finished in
                                                        self.scnView.frame.origin.x = 0
                                                })
                                        })
                                })
                        })
                })
        })
    }
    
    func handlePan(recognizer:UISwipeGestureRecognizer) {
        
        let translationX = recognizer.locationInView(contentView).x
        
        print(translationX)
        var xCoordBegin:CGFloat = 0.0
        
        switch recognizer.state {
        case .Began:
            xCoordBegin = translationX
        case .Changed:
            if (translationX > xCoordBegin) {
                if (scnView.frame.origin.x <= 67) {
                    scnView.frame.origin.x = translationX
                    whiteBackground.frame.origin.x = translationX
                } else {
                    parentViewController!.tabController!.swipeLeftView(translationX)
                }
            } else {
            }
            
            
//            if !isSettingsViewOpen {
//                thisView.frame = CGRectMake(0, translationY - self.view.frame.height , self.view.frame.width, self.view.frame.height)
//            } else {
//                thisView.frame = CGRectMake(0,self.view.frame.height - (self.view.frame.height - translationY) , self.view.frame.width, self.view.frame.height)
//            }
        case .Cancelled:
            print("cancelled")
        case .Ended:
            scnView.frame.origin.x = 0
            whiteBackground.frame.origin.x = 0
            
//            if !isSettingsViewOpen{
//                thisView.frame = CGRectMake(0, 0 , self.view.frame.width, self.view.frame.height)
//                isSettingsViewOpen = true
//            } else {
//                thisView.frame = CGRectMake(0, -(self.view.frame.height) , self.view.frame.width, self.view.frame.height)
//                isSettingsViewOpen = false
//            }
            
        default: break
        }
    }
    
    func toggleStar() {
        viewModel.toggleLike()
//        if SessionService.isLoggedIn {
//            viewModel.toggleLike()
//        } else {
//            parentViewController!.tabController!.hideUI()
//            parentViewController!.tabController!.lockUI()
//            
//            let loginOverlayViewController = LoginOverlayViewController(
//                title: "Login to like this moment",
//                successCallback: {
//                    self.viewModel.toggleLike()
//                },
//                cancelCallback: { true },
//                alwaysCallback: {
//                    self.parentViewController!.tabController!.unlockUI()
//                    self.parentViewController!.tabController!.showUI()
//                }
//            )
//            parentViewController!.presentViewController(loginOverlayViewController, animated: true, completion: nil)
//        }
    }
    
    func bindModel(optographId:UUID) {
        let optograph = Models.optographs[optographId]!.model
        let person = Models.persons[optograph.personID]!.model

        viewModel.bind(optographId)
        
        avatarImageView.kf_setImageWithURL(NSURL(string: ImageURL("persons/\(person.ID)/\(person.avatarAssetID).jpg", width: 47, height: 47))!)
        personNameView.text = person.displayName
        //dateView.text = optograph.createdAt.longDescription
        //textView.text = optograph.text
        
        if let locationID = optograph.locationID {
            let location = Models.locations[locationID]!.model
            locationTextView.text = "\(location.text), \(location.countryShort)"
            personNameView.align(.ToTheRightMatchingTop, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
            locationTextView.align(.ToTheRightMatchingBottom, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
            locationTextView.text = location.text
        } else {
            personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
            locationTextView.text = ""
        }
        
        likeButtonView.rac_hidden <~ viewModel.uploadStatus.producer.equalsTo(.Uploaded).map(negate)
        likeCountView.rac_hidden <~ viewModel.uploadStatus.producer.equalsTo(.Uploaded).map(negate)
        likeCountView.rac_text <~ viewModel.likeCount.producer.map { "\($0)" }
        
        viewModel.liked.producer.startWithNext { [weak self] liked in
            if let strongSelf = self {
                
                strongSelf.likeButtonView.setTitleColor(liked ? UIColor(0xffbc00) : .whiteColor(), forState: .Normal)
                strongSelf.likeButtonView.titleLabel?.font = UIFont.iconOfSize(24)
                //                    strongSelf.uploadButtonView.anchorInCorner(.BottomRight, xPad: 16, yPad: 130, width: 24, height: 24)
                //                    strongSelf.uploadTextView.align(.ToTheLeftCentered, relativeTo: strongSelf.uploadButtonView, padding: 8, width: 60, height: 13)
                //                    strongSelf.uploadingView.anchorInCorner(.BottomRight, xPad: 16, yPad: 130, width: 24, height: 24)
            }
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }   
    
    var id: Int = 0 {
        didSet {
            renderDelegate.id = id
        }
    }
    
    func getVisibleAndAdjacentPlaneIndices(direction: Direction) -> [CubeImageCache.Index] {
        let rotation = phiThetaToRotationMatrix(direction.phi, theta: direction.theta)
        return renderDelegate.getVisibleAndAdjacentPlaneIndicesFromRotationMatrix(rotation)
    }
    
    func setCubeImageCache(cache: CubeImageCache) {
        
        renderDelegate.nodeEnterScene = nil
        renderDelegate.nodeLeaveScene = nil
        
        renderDelegate.reset()
        
        renderDelegate.nodeEnterScene = { [weak self] index in
            dispatch_async(queue) {
                cache.get(index) { [weak self] (texture: SKTexture, index: CubeImageCache.Index) in
                    self?.renderDelegate.setTexture(texture, forIndex: index)
                    Async.main { [weak self] in
                        self?.loadingStatus.value = .Loaded
                    }
                }
            }
        }
        
        renderDelegate.nodeLeaveScene = { index in
            dispatch_async(queue) {
                cache.forget(index)
            }
        }
    }
    
    func willDisplay() {
        scnView.playing = UIDevice.currentDevice().deviceType != .Simulator
    }
    
    func didEndDisplay() {
        scnView.playing = false
        combinedMotionManager.reset()
        loadingStatus.value = .Nothing
        renderDelegate.reset()
    }
    
    func forgetTextures() {
        renderDelegate.reset()
    }
    
    deinit {
        logRetain()
    }
}

extension OptographCollectionViewCell: OptographOptions {
    dynamic func didTapOptions() {
        showOptions(viewModel.optographBox.model.ID, deleteCallback: deleteCallback)
    }
}
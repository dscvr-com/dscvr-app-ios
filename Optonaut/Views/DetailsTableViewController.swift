//
//  DetailsContainerView.swift
//  Optonaut
//
//  Created by Robert John Alkuino on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import Mixpanel
import Async
import SceneKit
import ReactiveCocoa
import Kingfisher
import SpriteKit
import SwiftyUserDefaults

let queue1 = dispatch_queue_create("detail_view", DISPATCH_QUEUE_SERIAL)

class DetailsTableViewController: UIViewController, NoNavbar,TabControllerDelegate, CubeRenderDelegateDelegate{
    
    private let viewModel: DetailsViewModel!
    
    private var combinedMotionManager: CombinedMotionManager!
    // subviews
    //private let tableView = TableView()
    
    private var renderDelegate: CubeRenderDelegate!
    private var scnView: SCNView!
    
    private var imageDownloadDisposable: Disposable?
    
    private var rotationAlert: UIAlertController?
    
    private enum LoadingStatus { case Nothing, Preview, Loaded }
    private let loadingStatus = MutableProperty<LoadingStatus>(.Nothing)
    let imageCache: CollectionImageCache
    
    var optographID:UUID = ""
    var cellIndexpath:Int = 0
    
    var direction: Direction {
        set(direction) {
            combinedMotionManager.setDirection(direction)
        }
        get {
            return combinedMotionManager.getDirection()
        }
    }
    
    private var touchStart: CGPoint?
    private let whiteBackground = UIView()
    private let avatarImageView = UIImageView()
    private let locationTextView = UILabel()
    private let likeCountView = UILabel()
    private let personNameView = BoundingLabel()
    private let optionsButtonView = BoundingButton()
    private let likeButtonView = BoundingButton()
    
    private let commentButtonView = BoundingButton()
    private let commentCountView = UILabel()
    
    private let hideSelectorButton = UIButton()
    private let littlePlanetButton = UIButton()
    private let gyroButton = UIButton()
    private var isSelectorButtonOpen:Bool = true
    private var isUIHide:Bool = false
    
    var isMe = false
    var labelShown = false
    var transformBegin:CGAffineTransform?
    let deleteButton = UIButton()
    var gyroImageActive = UIImage(named: "details_gyro_active")
    var gyroImageInactive = UIImage(named: "details_gyro_inactive")
    var backButton = UIImage(named: "back_yellow_icn")
    var shareButton = UIButton()
    
    let textButtonContainer = UIView()
    let textButton = UIButton()
    
    let imageButtonContainer = UIView()
    let imageButton = UIButton()
    
    let audioButtonContainer = UIView()
    let audioButton = UIButton()
    
    let markerNameLabel = UILabel()
    
    var sphereColor = UIColor()
    
    var attachmentToggled:Bool = false
    
    required init(optographId:UUID) {
        
        optographID = optographId
        
        viewModel = DetailsViewModel(optographID: optographId)
        let textureSize = getTextureWidth(UIScreen.mainScreen().bounds.width, hfov: HorizontalFieldOfView)
        imageCache = CollectionImageCache(textureSize: textureSize)
        
        logInit()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    func didEnterFrustrum(markerName: String, inFrustrum:Bool) {
        

//        markerNameLabel.hidden = false
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
            dispatch_async(dispatch_get_main_queue()){
                if inFrustrum {
                    self.markerNameLabel.text = markerName
                    self.markerNameLabel.sizeToFit()
                    self.markerNameLabel.center = CGPoint(x: self.view.center.x, y: 70.0)
                    
                    self.markerNameLabel.hidden = false
                    print("markerName: \(self.markerNameLabel.text!)")
                }
                else{
                    self.markerNameLabel.hidden = true
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .blackColor()
        
        navigationItem.title = ""
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: self.view.frame, options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
        } else {
            scnView = SCNView(frame: self.view.frame)
        }
        
        let hfov: Float = 40
        combinedMotionManager = CombinedMotionManager(sceneSize: scnView.frame.size, hfov: hfov)
        renderDelegate = CubeRenderDelegate(rotationMatrixSource: combinedMotionManager, width: scnView.frame.width, height: scnView.frame.height, fov: Double(hfov), cubeFaceCount: 2, autoDispose: true)
        renderDelegate.scnView = scnView
        renderDelegate.delegate = self
        scnView.scene = renderDelegate.scene
        scnView.delegate = renderDelegate
        scnView.backgroundColor = .clearColor()
        scnView.hidden = false
        self.view.addSubview(scnView)
        
        self.willDisplay()
        
        ///addd flags to control adding texture
        let cubeImageCache = imageCache.get(cellIndexpath, optographID: optographID, side: .Left)
        self.setCubeImageCache(cubeImageCache)
        ///addd flags to control adding texture
        
    }
    
    private func pushViewer(orientation: UIInterfaceOrientation) {
        
//        let viewerViewController = ViewerViewController(orientation: orientation, optograph: Models.optographs[optographID]!.model)
//        navigationController?.pushViewController(viewerViewController, animated: false)
//        //        viewModel.increaseViewsCount()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.OptographDetails")
        tabController!.delegate = self
        
        //viewModel.viewIsActive.value = true
        
        
        
        if let rotationSignal = RotationService.sharedInstance.rotationSignal {
            rotationSignal
                .skipRepeats()
                .filter([.LandscapeLeft, .LandscapeRight])
                //               .takeWhile { [weak self] _ in self?.viewModel.viewIsActive.value ?? false }
                .take(1)
                .observeOn(UIScheduler())
                .observeNext { [weak self] orientation in self?.pushViewer(orientation) }
        }
        
        let targetOverlay = UIView(frame: CGRect(x: 0, y: self.view.frame.size.height - 225, width: self.view.frame.size.width, height: 125))
        targetOverlay.backgroundColor = UIColor.blackColor().alpha(0.6)
        
        let pinImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        pinImage.backgroundColor = UIColor(hex:0xffd24e)
        
        let targetLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        targetLabel.text = "PLACE TARGET"
        targetLabel.font = UIFont(name: "Avenir-Heavy", size: 22.0)
        targetLabel.textColor = UIColor.whiteColor()
        targetLabel.sizeToFit()
        targetLabel.center = CGPoint(x: self.view.center.x + 20, y: targetLabel.frame.size.height)
        
        pinImage.center = CGPoint(x: targetLabel.frame.origin.x - 10, y: targetLabel.center.y)
        
        let addMedia = UIButton(frame: CGRect(x: pinImage.frame.origin.x - 30.0, y: pinImage.frame.origin.y + pinImage.frame.size.height + 20, width: 100.0, height: 35.0))
        addMedia.backgroundColor = UIColor(hex:0xffd24e)
        addMedia.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 13.0)
        addMedia.setTitle("ADD MEDIA", forState: UIControlState.Normal)
        addMedia.setTitleColor(UIColor.blackColor().alpha(0.6), forState: UIControlState.Normal)
        addMedia.layer.cornerRadius = 16.0
        addMedia.addTarget(self, action: #selector(toggleAttachmentButtons), forControlEvents: .TouchUpInside)
        
        let doneButton = UIButton(frame: CGRect(x: addMedia.frame.origin.x + addMedia.frame.size.width + 40.0, y: addMedia.frame.origin.y, width: 100.0, height: 35.0))
        doneButton.backgroundColor = UIColor(hex:0xffd24e)
        doneButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 13.0)
        doneButton.setTitle("DONE", forState: UIControlState.Normal)
        doneButton.setTitleColor(UIColor.blackColor().alpha(0.6), forState: UIControlState.Normal)
        doneButton.layer.cornerRadius = 17.0
        
        textButtonContainer.frame = CGRect(x: addMedia.frame.origin.x - 20.0, y: targetOverlay.frame.origin.y + targetOverlay.frame.size.height + 20.0, width: 80.0, height: 60.0)
        textButtonContainer.backgroundColor = UIColor.blackColor().alpha(0.6)
        textButtonContainer.layer.cornerRadius = 10.0
        
        textButton.frame = CGRect(x: 0, y: 0, width: 80.0, height: 60.0)
        textButton.backgroundColor = UIColor.clearColor()
        textButton.layer.cornerRadius = 10.0
        textButton.addTarget(self, action: #selector(textButtonDown), forControlEvents: .TouchUpInside)
        
        let textButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        textButtonLabel.text = "TEXT"
        textButtonLabel.font = UIFont(name:"Avenir-Book", size: 12.0)
        textButtonLabel.textColor = UIColor.whiteColor()
        textButtonLabel.sizeToFit()
        textButtonLabel.center = CGPoint(x: textButtonContainer.frame.size.width/2, y: textButtonContainer.frame.size.height - textButtonLabel.frame.size.height + 5)
        
        textButtonContainer.addSubview(textButtonLabel)
        textButtonContainer.addSubview(textButton)
        textButtonContainer.hidden = true
        
        imageButtonContainer.frame = CGRect(x: textButtonContainer.frame.origin.x + textButtonContainer.frame.size.width + 20.0, y: textButtonContainer.frame.origin.y, width: 80.0, height: 60.0)
        imageButtonContainer.backgroundColor = UIColor.blackColor().alpha(0.6)
        imageButtonContainer.layer.cornerRadius = 10.0
        
        imageButton.frame = CGRect(x: 0, y: 0, width: 80.0, height: 60.0)
        imageButton.backgroundColor = UIColor.clearColor()
        imageButton.layer.cornerRadius = 10.0
        imageButton.addTarget(self, action: #selector(imageButtonDown), forControlEvents: .TouchUpInside)
        
        let imageButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        imageButtonLabel.text = "IMAGE"
        imageButtonLabel.font = UIFont(name:"Avenir-Book", size: 12.0)
        imageButtonLabel.textColor = UIColor.whiteColor()
        imageButtonLabel.sizeToFit()
        imageButtonLabel.center = CGPoint(x: imageButtonContainer.frame.size.width/2, y: imageButtonContainer.frame.size.height - imageButtonLabel.frame.size.height + 5)
        
        imageButtonContainer.addSubview(imageButtonLabel)
        imageButtonContainer.addSubview(imageButton)
        imageButtonContainer.hidden = true
        
        audioButtonContainer.frame = CGRect(x: imageButtonContainer.frame.origin.x + imageButtonContainer.frame.size.width + 20.0, y: imageButtonContainer.frame.origin.y, width: 80.0, height: 60.0)
        audioButtonContainer.backgroundColor = UIColor.blackColor().alpha(0.6)
        audioButtonContainer.layer.cornerRadius = 10.0
        
        audioButton.frame = CGRect(x: 0, y: 0, width: 80.0, height: 60.0)
        audioButton.backgroundColor = UIColor.clearColor()
        audioButton.layer.cornerRadius = 10.0
        audioButton.addTarget(self, action: #selector(audioButtonDown), forControlEvents: .TouchUpInside)
        
        let audioButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        audioButtonLabel.text = "AUDIO"
        audioButtonLabel.font = UIFont(name:"Avenir-Book", size: 12.0)
        audioButtonLabel.textColor = UIColor.whiteColor()
        audioButtonLabel.sizeToFit()
        audioButtonLabel.center = CGPoint(x: audioButtonContainer.frame.size.width/2, y: audioButtonContainer.frame.size.height - audioButtonLabel.frame.size.height + 5)
        
        audioButtonContainer.addSubview(audioButtonLabel)
        audioButtonContainer.addSubview(audioButton)
        audioButtonContainer.hidden = true
        
        self.markerNameLabel.frame = audioButtonLabel.frame
        self.markerNameLabel.font = UIFont(name:"Avenir-Book", size: 12.0)
        self.markerNameLabel.backgroundColor = UIColor.whiteColor()
        self.markerNameLabel.textColor = UIColor.blackColor()
        self.markerNameLabel.text = "text"
        self.markerNameLabel.hidden = true
        
        targetOverlay.addSubview(addMedia)
        targetOverlay.addSubview(doneButton)
        targetOverlay.addSubview(pinImage)
        targetOverlay.addSubview(targetLabel)
        
        //add toggling buttons
        
        self.view.addSubview(targetOverlay)
        self.view.addSubview(textButtonContainer)
        self.view.addSubview(imageButtonContainer)
        self.view.addSubview(audioButtonContainer)
        self.view.addSubview(self.markerNameLabel)
        
        //        viewModel.optographReloaded.producer.startWithNext { [weak self] in
        //            if self?.viewModel.optograph.deletedAt != nil {
        //                self?.navigationController?.popViewControllerAnimated(false)
        //            }
        //        }
        
        ///add flags to check if editing optograph
        /**/
        whiteBackground.backgroundColor = UIColor.blackColor().alpha(0.60)
        self.view.addSubview(whiteBackground)
        
        avatarImageView.layer.cornerRadius = 23.5
        avatarImageView.layer.borderColor = UIColor(hex:0xffbc00).CGColor
        avatarImageView.layer.borderWidth = 2.0
        avatarImageView.backgroundColor = .whiteColor()
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pushProfile)))
        avatarImageView.kf_setImageWithURL(NSURL(string: ImageURL(viewModel.avatarImageUrl.value, width: 47, height: 47))!)
        whiteBackground.addSubview(avatarImageView)
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(21)
        optionsButtonView.setImage(UIImage(named:"follow_active"), forState: .Normal)
        optionsButtonView.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        optionsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.followUser)))
        whiteBackground.addSubview(optionsButtonView)
        
        personNameView.font = UIFont.displayOfSize(15, withType: .Regular)
        personNameView.textColor = UIColor(0xffbc00)
        personNameView.userInteractionEnabled = true
        personNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.pushProfile)))
        whiteBackground.addSubview(personNameView)
        
        likeButtonView.addTarget(self, action: #selector(self.toggleStar), forControlEvents: [.TouchDown])
        whiteBackground.addSubview(likeButtonView)
        
        
        commentButtonView.setImage(UIImage(named:"comment_icn"), forState: .Normal)
        commentButtonView.addTarget(self, action: #selector(self.toggleComment), forControlEvents: [.TouchDown])
        whiteBackground.addSubview(commentButtonView)
        
        commentCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        commentCountView.textColor = .whiteColor()
        commentCountView.textAlignment = .Right
        whiteBackground.addSubview(commentCountView)
        
        locationTextView.font = UIFont.displayOfSize(11, withType: .Light)
        locationTextView.textColor = UIColor.whiteColor()
        whiteBackground.addSubview(locationTextView)
        
        likeCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        likeCountView.textColor = .whiteColor()
        likeCountView.textAlignment = .Right
        whiteBackground.addSubview(likeCountView)
        
        whiteBackground.anchorAndFillEdge(.Bottom, xPad: 0, yPad: 0, otherSize: 66)
        avatarImageView.anchorToEdge(.Left, padding: 20, width: 47, height: 47)
        personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
        likeButtonView.anchorInCorner(.BottomRight, xPad: 16, yPad: 21, width: 24, height: 28)
        
        likeCountView.align(.ToTheLeftCentered, relativeTo: likeButtonView, padding: 10, width:20, height: 13)
        /**/
        ///add flags to check if editing optograph
        
        //commentButtonView.align(.ToTheLeftCentered, relativeTo: likeCountView, padding: 10, width:24, height: 28)
        //commentCountView.align(.ToTheLeftCentered, relativeTo: commentButtonView, padding: 10, width:20, height: 13)
        
        let followSizeWidth = UIImage(named:"follow_active")!.size.width
        let followSizeHeight = UIImage(named:"follow_active")!.size.height
        
        optionsButtonView.frame = CGRect(x: avatarImageView.frame.origin.x + 2 - (followSizeWidth / 2),y: avatarImageView.frame.origin.y + (avatarImageView.frame.height * 0.75) - (followSizeWidth / 2),width: followSizeWidth,height: followSizeHeight)
        
        personNameView.rac_text <~ viewModel.creator_username
        likeCountView.rac_text <~ viewModel.starsCount.producer.map { "\($0)" }
        //commentCountView.rac_text <~ viewModel.commentsCount.producer.map{ "\($0)" }
        
        viewModel.isStarred.producer.startWithNext { [weak self] liked in
            if let strongSelf = self {
                strongSelf.likeButtonView.setImage(liked ? UIImage(named:"liked_button") : UIImage(named:"user_unlike_icn"), forState: .Normal)
            }
        }
        
        let optograph = Models.optographs[optographID]!.model
        
        if let locationID = optograph.locationID {
            let location = Models.locations[locationID]!.model
            locationTextView.text = "\(location.text), \(location.countryShort)"
            self.personNameView.align(.ToTheRightMatchingTop, relativeTo: self.avatarImageView, padding: 15, width: 100, height: 18)
            self.locationTextView.align(.ToTheRightMatchingBottom, relativeTo: self.avatarImageView, padding: 15, width: 100, height: 18)
            locationTextView.text = location.text
        } else {
            personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
            locationTextView.text = ""
        }
        
        
        //hideSelectorButton.setBackgroundImage(UIImage(named:"oval_up"), forState: .Normal)
        //self.view.addSubview(hideSelectorButton)
        
        //self.view.addSubview(littlePlanetButton)
        //self.view.addSubview(gyroButton)
        
        
//        hideSelectorButton.anchorInCorner(.TopRight, xPad: 10, yPad: 70, width: 40, height: 40)
//        hideSelectorButton.addTarget(self, action: #selector(self.selectorButton), forControlEvents:.TouchUpInside)
//        
//        littlePlanetButton.align(.UnderCentered, relativeTo: hideSelectorButton, padding: 10, width: 35, height: 35)
//        littlePlanetButton.addTarget(self, action: #selector(self.littlePlanetButtonTouched), forControlEvents:.TouchUpInside)
        
//        gyroButton.align(.UnderCentered, relativeTo: littlePlanetButton, padding: 10, width: 35, height: 35)
        
//        gyroButton.anchorInCorner(.TopRight, xPad: 20, yPad: 30, width: 40, height: 40)
//        gyroButton.userInteractionEnabled = true
//        gyroButton.addTarget(self, action: #selector(self.gyroButtonTouched), forControlEvents:.TouchUpInside)
        
        gyroImageActive = gyroImageActive?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        gyroImageInactive = gyroImageInactive?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        backButton = backButton?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backButton, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(closeDetailsPage))
        
        if  Defaults[.SessionGyro] {
            self.changeButtonIcon(true)
        } else {
            self.changeButtonIcon(false)
        }
        
        let oneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.oneTap(_:)))
        oneTapGestureRecognizer.numberOfTapsRequired = 1
        self.scnView.addGestureRecognizer(oneTapGestureRecognizer)
        
        //        let twoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.twoTap(_:)))
        //        twoTapGestureRecognizer.numberOfTapsRequired = 2
        //        self.view.addGestureRecognizer(twoTapGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGesture(_:)))
        
        scnView.addGestureRecognizer(pinchGestureRecognizer)
        
        
        isMe = viewModel.isMe
        
        if isMe {
            optionsButtonView.hidden = true
        } else {
            optionsButtonView.hidden = false
            viewModel.isFollowed.producer.startWithNext{
                $0 ? self.optionsButtonView.setImage(UIImage(named:"follow_active"), forState: .Normal) : self.optionsButtonView.setImage(UIImage(named:"follow_inactive"), forState: .Normal)
            }
        }
        if isMe {
            deleteButton.setBackgroundImage(UIImage(named: "profile_delete_icn"), forState: .Normal)
            deleteButton.addTarget(self, action: #selector(deleteOpto), forControlEvents: .TouchUpInside)
            whiteBackground.addSubview(deleteButton)
            
            let deleteImageSize = UIImage(named:"profile_delete_icn")?.size
            deleteButton.align(.ToTheLeftCentered, relativeTo: likeCountView, padding: 10, width:(deleteImageSize?.width)!, height: (deleteImageSize?.height)!)
            
            shareButton.setBackgroundImage(UIImage(named: "share_white_details"), forState: .Normal)
            shareButton.addTarget(self, action: #selector(share), forControlEvents: .TouchUpInside)
            whiteBackground.addSubview(shareButton)
            
            let shareImageSize = UIImage(named:"share_white_details")?.size
            shareButton.align(.ToTheLeftCentered, relativeTo: deleteButton, padding: 20, width:(shareImageSize?.width)!, height: (shareImageSize?.height)!)
        } else {
            shareButton.setBackgroundImage(UIImage(named: "share_white_details"), forState: .Normal)
            shareButton.addTarget(self, action: #selector(share), forControlEvents: .TouchUpInside)
            whiteBackground.addSubview(shareButton)
            
            let shareImageSize = UIImage(named:"share_white_details")?.size
            shareButton.align(.ToTheLeftCentered, relativeTo: likeCountView, padding: 10, width:(shareImageSize?.width)!, height: (shareImageSize?.height)!)
        }
        
    }
    func share() {
        let share = DetailsShareViewController()
        share.optographId = optographID
        self.navigationController?.presentViewController(share, animated: true, completion: nil)
    }
    
    
    func toggleAttachmentButtons() {
        
        if attachmentToggled{
            textButtonContainer.hidden = true
            imageButtonContainer.hidden = true
            audioButtonContainer.hidden = true
            
            attachmentToggled = false
        }
        else{
            textButtonContainer.hidden = false
            imageButtonContainer.hidden = false
            audioButtonContainer.hidden = false
            
            attachmentToggled = true
        }
        
    }
    
    
    //create a function with button tag switch for color changes
    func textButtonDown(){
        renderDelegate.addMarker(UIColor.blueColor(), type:"Text Item")
    }
    
    func imageButtonDown(){
        renderDelegate.addMarker(UIColor.redColor(), type:"Image Item")
    }
    
    func audioButtonDown(){
        renderDelegate.addMarker(UIColor.greenColor(), type:"Audio Item")
    }
    
    func deleteOpto() {
        print("test")
//        renderDelegate.addMarker(sphereColor)
        
        
        /*
        
        if SessionService.isLoggedIn {
            let alert = UIAlertController(title:"Are you sure?", message: "Do you really want to delete this 360 image? You cannot undo this.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { _ in
                self.viewModel.deleteOpto()
                self.closeDetailsPage()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
            
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title:"", message: "Please login to delete this 360 image.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        }
 
 */
    }
    func closeDetailsPage() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func toggleComment() {
        let commentPage = CommentTableViewController(optographID: optographID)
        //commentPage.modalPresentationStyle = .OverCurrentContext
        self.navigationController?.presentViewController(commentPage, animated: true, completion: nil)
    }
    
    func pinchGesture(recognizer:UIPinchGestureRecognizer) {
        
        if let view = recognizer.view {
            if recognizer.state == UIGestureRecognizerState.Began {
                hideUI()
                if transformBegin == nil {
                    transformBegin = CGAffineTransformScale(view.transform,recognizer.scale, recognizer.scale)
                }
            } else if recognizer.state == UIGestureRecognizerState.Changed {
                print(">>",view.transform.a)
                print(recognizer.scale)
                if view.transform.a >= 1.0  {
                    scnView.transform = CGAffineTransformScale(view.transform,recognizer.scale, recognizer.scale)
                    recognizer.scale = 1
                } else {
                    scnView.transform = transformBegin!
                    recognizer.scale = 1
                }
            } else if recognizer.state == UIGestureRecognizerState.Ended {
                if view.transform.a <= 1.0  {
                    scnView.transform = transformBegin!
                    recognizer.scale = 1
                }
            }
        }
    }
    
    func toggleStar() {
        //        if SessionService.isLoggedIn {
        //            viewModel.toggleLike()
        //        } else {
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
        
        if SessionService.isLoggedIn {
            viewModel.toggleLike()
        } else {
            let alert = UIAlertController(title:"", message: "Please login to like this moment.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        }
    }
    dynamic private func pushProfile() {
        let profilepage = ProfileCollectionViewController(personID: viewModel.optographBox.model.personID)
        profilepage.isProfileVisit = true
        navigationController?.pushViewController(profilepage, animated: true)
    }
    
    func followUser() {
        
        if SessionService.isLoggedIn {
            viewModel.toggleFollow()
        } else {
            let alert = UIAlertController(title:"", message: "Please login to follow this user", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func hideUI() {
        self.whiteBackground.hidden = true
        self.hideSelectorButton.hidden = true
        //self.gyroButton.hidden = true
        self.littlePlanetButton.hidden = true
        self.isUIHide = true
        self.navigationController?.navigationBarHidden = true
    }
    
    func showUI() {
        self.whiteBackground.hidden = false
        self.hideSelectorButton.hidden = false
        //self.gyroButton.hidden = false
        self.littlePlanetButton.hidden = false
        self.isUIHide = false
        self.navigationController?.navigationBarHidden = false
    }
    
    func oneTap(recognizer:UITapGestureRecognizer) {
        if !isUIHide {
            UIView.animateWithDuration(0.4,delay: 0.3, options: .CurveEaseOut, animations: {
                self.whiteBackground.hidden = true
                self.hideSelectorButton.hidden = true
                //self.gyroButton.hidden = true
                self.littlePlanetButton.hidden = true
                self.isUIHide = true
                },completion: nil)
            self.navigationController?.navigationBarHidden = true
        } else {
            UIView.animateWithDuration(0.4,delay: 0.3, options: .CurveEaseOut, animations: {
                self.whiteBackground.hidden = false
                self.hideSelectorButton.hidden = false
                //self.gyroButton.hidden = false
                self.littlePlanetButton.hidden = false
                self.isUIHide = false
                },completion: nil)
            self.navigationController?.navigationBarHidden = false
        }
    }
    
    func twoTap(recognizer:UITapGestureRecognizer) {
        print("two tap")
        navigationController?.popViewControllerAnimated(true)
    }
    
    func selectorButton() {
        if isSelectorButtonOpen {
            closeSelector()
            isSelectorButtonOpen = false
        } else {
            openSelector()
            isSelectorButtonOpen = true
        }
    }
    
    
    func openSelector() {
        
        self.hideSelectorButton.setBackgroundImage(UIImage(named:"oval_up"), forState: .Normal)
        
        UIView.animateWithDuration(0.4,delay: 0.3, options: .CurveEaseOut, animations: {
            self.littlePlanetButton.hidden = false
            self.littlePlanetButton.align(.UnderCentered, relativeTo: self.hideSelectorButton, padding: 10, width: 35, height: 35)
            },completion: { finished in
                UIView.animateWithDuration(0.4,delay: 0.2, options: .CurveEaseOut, animations: {
                    self.gyroButton.hidden =  false
                    self.gyroButton.align(.UnderCentered, relativeTo: self.littlePlanetButton, padding: 10, width: 35, height: 35)
                    },completion: nil)
        })
        
    }
    func closeSelector() {
        UIView.animateWithDuration(0.4,delay: 0.3, options: .CurveEaseOut, animations: {
            self.gyroButton.frame.origin.y = self.littlePlanetButton.frame.origin.y
            },completion: { finished in
                self.gyroButton.hidden = true
                UIView.animateWithDuration(0.4,delay: 0.2, options: .CurveEaseOut, animations: {
                    self.littlePlanetButton.frame.origin.y = self.hideSelectorButton.frame.origin.y
                    },completion: { completed in
                        self.littlePlanetButton.hidden = true
                        self.hideSelectorButton.setBackgroundImage(UIImage(named:"oval_down"), forState: .Normal)
                })
        })
    }
    
    func littlePlanetButtonTouched() {
        Defaults[.SessionGyro] = false
        self.changeButtonIcon(false)
    }
    
    func gyroButtonTouched() {
        if Defaults[.SessionGyro] {
            Defaults[.SessionGyro] = false
            self.changeButtonIcon(false)
        } else {
            Defaults[.SessionGyro] = true
            self.changeButtonIcon(true)
        }
    }
    
    func changeButtonIcon(isGyro:Bool) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: isGyro ? gyroImageActive : gyroImageInactive, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(gyroButtonTouched))
        
//        if isGyro {
//            //littlePlanetButton.setBackgroundImage(UIImage(named:"details_littlePlanet_inactive"), forState: .Normal)
//            gyroButton.setBackgroundImage(UIImage(named:"details_gyro_active"), forState: .Normal)
//            
//        } else {
//            //littlePlanetButton.setBackgroundImage(UIImage(named:"details_littlePlanet_active"), forState: .Normal)
//            gyroButton.setBackgroundImage(UIImage(named:"details_gyro_inactive"), forState: .Normal)
//        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        let point = touches.first!.locationInView(scnView)
        touchStart = point
        
        if touches.count == 1 {
            combinedMotionManager.touchStart(point)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        let point = touches.first!.locationInView(scnView)
        combinedMotionManager.touchMove(point)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        _ = touchStart!.distanceTo(touches.first!.locationInView(self.view))
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
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        //Mixpanel.sharedInstance().track("View.OptographDetails", properties: ["optograph_id": viewModel.optograph.ID, "optograph_description" : viewModel.optograph.text])
        Mixpanel.sharedInstance().track("View.OptographDetails", properties: ["optograph_id": "", "optograph_description" : ""])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tabController!.disableScrollView()
        
        CoreMotionRotationSource.Instance.start()
        RotationService.sharedInstance.rotationEnable()
        
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DetailsTableViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        //        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DetailsTableViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        updateNavbarAppear()
        
        //self.navigationController?.navigationBar.tintColor = UIColor(hex:0xffbc00)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        imageDownloadDisposable?.dispose()
        imageDownloadDisposable = nil
//        CoreMotionRotationSource.Instance.stop()
        RotationService.sharedInstance.rotationDisable()
        tabController!.enableScrollView()
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //        tableView.contentOffset = CGPoint(x: 0, y: -(tableView.frame.height - 78))
        //        tableView.contentInset = UIEdgeInsets(top: tableView.frame.height - 78, left: 0, bottom: 10, right: 0)
    }
    
    //    func keyboardWillShow(notification: NSNotification) {
    //        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
    //        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
    //    }
    //
    //    func keyboardWillHide(notification: NSNotification) {
    //        tableView.contentInset = UIEdgeInsets(top: tableView.frame.height - 78, left: 0, bottom: 10, right: 0)
    //    }
    
    func dismissKeyboard() {
        view.endEditing(true)
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
            dispatch_async(queue1) {
                cache.get(index) { [weak self] (texture: SKTexture, index: CubeImageCache.Index) in
                    self?.renderDelegate.setTexture(texture, forIndex: index)
                    Async.main { [weak self] in
                        self?.loadingStatus.value = .Loaded
                    }
                }
            }
        }
        
        renderDelegate.nodeLeaveScene = { index in
            dispatch_async(queue1) {
                cache.forget(index)
            }
        }
    }
    
    func willDisplay() {
        scnView.playing = true
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
    //    private func pushViewer(orientation: UIInterfaceOrientation) {
    //        rotationAlert?.dismissViewControllerAnimated(true, completion: nil)
    //        let viewerViewController = ViewerViewController(orientation: orientation, optograph: viewModel.optograph)
    //        viewerViewController.hidesBottomBarWhenPushed = true
    //        navigationController?.pushViewController(viewerViewController, animated: false)
    //        viewModel.increaseViewsCount()
    //    }
    
    func showRotationAlert() {
        rotationAlert = UIAlertController(title: "Rotate counter clockwise", message: "Please rotate your phone counter clockwise by 90 degree.", preferredStyle: .Alert)
        rotationAlert!.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        self.navigationController?.presentViewController(rotationAlert!, animated: true, completion: nil)
    }
    
}

//// MARK: - UITableViewDelegate
//extension DetailsTableViewController: UITableViewDelegate {
//
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
////        let superView = tableView!.superview!
//        if indexPath.row == 0 {
//            let yOffset = max(0, tableView.frame.height - tableView.contentSize.height)
//            UIView.animateWithDuration(0.2, delay: 0, options: [.BeginFromCurrentState],
//                animations: {
//                    self.tableView.contentOffset = CGPoint(x: 0, y: -yOffset)
//                },
//                completion: nil)
//        }
//    }
//
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        if indexPath.row == 0 {
//            let infoHeight = CGFloat(78)
//            let textWidth = view.frame.width - 40
//            let textHeight = calcTextHeight(viewModel.text.value, withWidth: textWidth, andFont: UIFont.textOfSize(14, withType: .Regular)) + 20
//            let hashtagsHeight = calcTextHeight(viewModel.hashtags.value, withWidth: textWidth, andFont: UIFont.textOfSize(14, withType: .Semibold)) + 25
//            return textHeight + hashtagsHeight + infoHeight
//        } else if indexPath.row == 1 {
//            return 60
//        } else {
//            let textWidth = view.frame.width - 40 - 40 - 20 - 30 - 20
//            let textHeight = calcTextHeight(viewModel.comments.value[indexPath.row - 2].text, withWidth: textWidth, andFont: UIFont.textOfSize(13, withType: .Regular)) + 15
//            return max(textHeight, 60)
//        }
//    }
//
//}
//
//// MARK: - UITableViewDataSource
//extension DetailsTableViewController: UITableViewDataSource {
//
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        if indexPath.row == 0 {
//            let cell = self.tableView.dequeueReusableCellWithIdentifier("details-cell") as! DetailsTableViewCell
//            cell.viewModel = viewModel
//            cell.navigationController = navigationController as? NavigationController
//            cell.bindViewModel()
//            return cell
//        }
//    }
//
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return viewModel.comments.value.count + 2
//    }
//
//}
//
//
//// MARK: - NewCommentTableViewDelegate
//extension DetailsTableViewController: NewCommentTableViewDelegate {
//    func newCommentAdded(comment: Comment) {
//        self.viewModel.insertNewComment(comment)
//    }
//}

//private class TableView: UITableView {
//
//    var horizontalScrollDistanceCallback: ((Float) -> ())?
//
//    private override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        super.touchesMoved(touches, withEvent: event)
//
//        if let touch = touches.first {
//            let oldPoint = touch.previousLocationInView(self)
//            let newPoint = touch.locationInView(self)
//            self.horizontalScrollDistanceCallback?(Float(newPoint.x - oldPoint.x))
//        }
//    }
//
//    private override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
//        // this took a lot of time. don't bother to understand this
//        if frame.height + contentOffset.y - 78 < 80 && point.y < 0 && frame.width - point.x < 100 {
//            return false
//        }
//        return true
//    }
//    
//}
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
import AssetsLibrary
import ImageIO

let queue1 = dispatch_queue_create("detail_view", DISPATCH_QUEUE_SERIAL)

class DetailsTableViewController: UIViewController, NoNavbar,TabControllerDelegate, CubeRenderDelegateDelegate{
    
    private let viewModel: DetailsViewModel!
    
    
    private var combinedMotionManager: CombinedMotionManager!
    // subviews
    //private let tableView = TableView()
    
    private var renderDelegate: CubeRenderDelegate!
    private var scnView: SCNView!
    
    private var rotationAlert: UIAlertController?
    
    private enum LoadingStatus { case Nothing, Preview, Loaded }
    private let loadingStatus = MutableProperty<LoadingStatus>(.Nothing)
    let imageCache: CollectionImageCache
    
    var optographID:UUID = ""
    var cellIndexpath:Int = 0
    var countDown:Int = 3
    var last_optographID:UUID = ""
    private var lastElapsedTime = CACurrentMediaTime() ;
    
    
    
    var optographTopPick:NSArray = []
    
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
    var transformBegin:CGAffineTransform?
    let deleteButton = UIButton()
    
    var gyroImageActive = UIImage(named: "details_gyro_active")
    var gyroImageInactive = UIImage(named: "details_gyro_inactive")
    var vrIcon = UIImage(named: "vr_icon")
    
    var backButton = UIImage(named: "back_yellow_icn")
    var shareButton = UIButton()
    var gyroTypeBtn = UIButton()
    var eliteImageView = UIImageView()
    var descriptionLabel = UILabel()
    var exportButton = UIButton()
    var descriptionOpen:Bool = false
    
    var isStory: Bool = false
    var storyNodes: [StorytellingChildren] = []
    private var isInsideStory: Bool = false
    
    required init(optoList:[UUID]) {
        
        optographID = optoList[0]
        optographTopPick = optoList
        
        viewModel = DetailsViewModel(optographID: optographID)
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
        let cubeImageCache = imageCache.get(cellIndexpath, optographID: optographID, side: .Left)
        self.setCubeImageCache(cubeImageCache)
        
    }
    
    private func pushViewer(orientation: UIInterfaceOrientation) {
        
        let viewerViewController = ViewerViewController(orientation: orientation, arrayOfoptograph: optographTopPick as! [UUID] ,selfOptograph:optographID )
        navigationController?.pushViewController(viewerViewController, animated: false)
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
        
        //        viewModel.optographReloaded.producer.startWithNext { [weak self] in
        //            if self?.viewModel.optograph.deletedAt != nil {
        //                self?.navigationController?.popViewControllerAnimated(false)
        //            }
        //        }
        whiteBackground.backgroundColor = UIColor.blackColor().alpha(0.60)
        self.view.addSubview(whiteBackground)
        
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .whiteColor()
        descriptionLabel.backgroundColor = UIColor.clearColor()
        descriptionLabel.font = UIFont(name: "HelveticaNeue-ThinItalic",size: 15)
        self.view.addSubview(descriptionLabel)
        descriptionLabel.userInteractionEnabled = true
        descriptionLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.adjustDescriptionLabel(_:))))
        
        avatarImageView.layer.cornerRadius = 23.5
        avatarImageView.layer.borderColor = UIColor(hex:0xFF5E00).CGColor
        avatarImageView.layer.borderWidth = 2.0
        avatarImageView.backgroundColor = .whiteColor()
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pushProfile)))
        avatarImageView.kf_setImageWithURL(NSURL(string: ImageURL(viewModel.avatarImageUrl.value, width: 47, height: 47))!)
        whiteBackground.addSubview(avatarImageView)
        
        eliteImageView.image = UIImage(named: "elite_beta_icn")!
        whiteBackground.addSubview(eliteImageView)
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(21)
        optionsButtonView.setImage(UIImage(named:"follow_active"), forState: .Normal)
        optionsButtonView.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        optionsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.followUser)))
        whiteBackground.addSubview(optionsButtonView)
        
        personNameView.font = UIFont.displayOfSize(15, withType: .Regular)
        personNameView.textColor = UIColor(0xFF5E00)
        personNameView.userInteractionEnabled = true
        personNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.pushProfile)))
        whiteBackground.addSubview(personNameView)
        
        likeButtonView.addTarget(self, action: #selector(self.toggleStar), forControlEvents: [.TouchDown])
        whiteBackground.addSubview(likeButtonView)
        
        
        //        commentButtonView.setImage(UIImage(named:"comment_icn"), forState: .Normal)
        //        commentButtonView.addTarget(self, action: #selector(self.toggleComment), forControlEvents: [.TouchDown])
        //        whiteBackground.addSubview(commentButtonView)
        //
        //        commentCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        //        commentCountView.textColor = .whiteColor()
        //        commentCountView.textAlignment = .Right
        //        whiteBackground.addSubview(commentCountView)
        
        locationTextView.font = UIFont.displayOfSize(11, withType: .Light)
        locationTextView.textColor = UIColor.whiteColor()
        whiteBackground.addSubview(locationTextView)
        
        likeCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        likeCountView.textColor = .whiteColor()
        likeCountView.textAlignment = .Right
        whiteBackground.addSubview(likeCountView)
        
        whiteBackground.anchorAndFillEdge(.Bottom, xPad: 0, yPad: 0, otherSize: 66)
        let deleteImageSize1 = UIImage(named:"profile_delete_icn")?.size
        descriptionLabel.frame = CGRect(x: whiteBackground.frame.origin.x + 10,y: view.frame.height - whiteBackground.frame.height - 30,width: view.frame.width - 30 - (deleteImageSize1?.width)!,height: 20)
        
        avatarImageView.anchorToEdge(.Left, padding: 20, width: 47, height: 47)
        personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
        likeButtonView.anchorInCorner(.BottomRight, xPad: 16, yPad: 21, width: 24, height: 28)
        likeCountView.align(.ToTheLeftCentered, relativeTo: likeButtonView, padding: 10, width:20, height: 13)
        
        
        let followSizeWidth = UIImage(named:"follow_active")!.size.width
        let followSizeHeight = UIImage(named:"follow_active")!.size.height
        
        optionsButtonView.frame = CGRect(x: avatarImageView.frame.origin.x + 2 - (followSizeWidth / 2),y: avatarImageView.frame.origin.y + (avatarImageView.frame.height * 0.75) - (followSizeWidth / 2),width: followSizeWidth,height: followSizeHeight)
        
        let icnWidth = UIImage(named: "elite_beta_icn")!
        eliteImageView.anchorInCorner(.BottomLeft, xPad: optionsButtonView.frame.origin.x + (optionsButtonView.frame.width/2), yPad: 6, width: icnWidth.size.width, height: icnWidth.size.height)
        
        personNameView.rac_text <~ viewModel.creator_username
        likeCountView.rac_text <~ viewModel.starsCount.producer.map { "\($0)" }
        descriptionLabel.rac_text <~ viewModel.text
        
        commentCountView.rac_text <~ viewModel.commentsCount.producer.map{ "\($0)" }
        
        viewModel.isStarred.producer.startWithNext { [weak self] liked in
            if let strongSelf = self {
                strongSelf.likeButtonView.setImage(liked ? UIImage(named:"liked_button") : UIImage(named:"user_unlike_icn"), forState: .Normal)
            }
        }
        
        viewModel.locationText.producer.startWithNext{ val in
            if val == "" {
                self.personNameView.align(.ToTheRightCentered, relativeTo: self.avatarImageView, padding: 9.5, width: 100, height: 18)
                self.locationTextView.text = ""
            } else {
                self.locationTextView.text = val
                self.personNameView.align(.ToTheRightMatchingTop, relativeTo: self.avatarImageView, padding: 15, width: 100, height: 18)
                self.locationTextView.align(.ToTheRightMatchingBottom, relativeTo: self.avatarImageView, padding: 15, width: 100, height: 18)
            }
            
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
        
        self.view.addSubview(gyroTypeBtn)
        gyroTypeBtn.anchorInCorner(.TopRight, xPad: 10, yPad: 70, width: 40, height: 40)
        gyroTypeBtn.addTarget(self, action: #selector(gyroButtonTouched), forControlEvents:.TouchUpInside)
        
        
        if  Defaults[.SessionGyro] {
            self.changeButtonIcon(true)
        } else {
            self.changeButtonIcon(false)
        }
        
        vrIcon = vrIcon?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        let vrButton = UIBarButtonItem(image:vrIcon , style: UIBarButtonItemStyle.Plain, target: self, action: #selector(vrIconTouched))
        let exportBtn = UIBarButtonItem(image:UIImage(named:"export_icn") , style: UIBarButtonItemStyle.Plain, target: self, action: #selector(exportImage))
        exportBtn.tintColor = UIColor.whiteColor()
        
        navigationItem.rightBarButtonItems = [vrButton,exportBtn]
        
        backButton = backButton?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backButton, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(closeDetailsPage))
        
        let oneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.oneTap(_:)))
        oneTapGestureRecognizer.numberOfTapsRequired = 1
        self.scnView.addGestureRecognizer(oneTapGestureRecognizer)
        
        //                let twoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.twoTap(_:)))
        //                twoTapGestureRecognizer.numberOfTapsRequired = 2
        //                self.view.addGestureRecognizer(twoTapGestureRecognizer)
        
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
            self.view.addSubview(deleteButton)
            
            let deleteImageSize = UIImage(named:"profile_delete_icn")?.size
            deleteButton.align(.AboveMatchingRight, relativeTo: whiteBackground, padding: 10, width: (deleteImageSize?.width)!, height: (deleteImageSize?.height)!)
            
            deleteButton.anchorInCorner(.BottomRight, xPad: 15, yPad: 76, width: (deleteImageSize?.width)!, height: (deleteImageSize?.height)!)
            
            shareButton.setBackgroundImage(UIImage(named: "share_white_details"), forState: .Normal)
            shareButton.addTarget(self, action: #selector(share), forControlEvents: .TouchUpInside)
            whiteBackground.addSubview(shareButton)
            
            let shareImageSize = UIImage(named:"share_white_details")?.size
            shareButton.align(.ToTheLeftCentered, relativeTo: likeCountView, padding: 10, width:(shareImageSize?.width)!, height: (shareImageSize?.height)!)
            
            
        } else {
            shareButton.setBackgroundImage(UIImage(named: "share_white_details"), forState: .Normal)
            shareButton.addTarget(self, action: #selector(share), forControlEvents: .TouchUpInside)
            whiteBackground.addSubview(shareButton)
            
            let shareImageSize = UIImage(named:"share_white_details")?.size
            shareButton.align(.ToTheLeftCentered, relativeTo: likeCountView, padding: 10, width:(shareImageSize?.width)!, height: (shareImageSize?.height)!)
        }
        
        viewModel.isElite.producer.startWithNext{ val in
            if val == 0 {
                self.eliteImageView.hidden = true
            } else {
                self.eliteImageView.hidden = false
            }
            
        }
        let commentButtonSize = UIImage(named:"comment_icn")!.size
        
        commentButtonView.align(.ToTheLeftCentered, relativeTo: shareButton, padding: 20, width:commentButtonSize.width, height: commentButtonSize.height)
        commentCountView.align(.ToTheLeftCentered, relativeTo: commentButtonView, padding: 10, width:20, height: 13)
        
        //        viewModel.isPublished.producer.startWithNext { val in
        //            if val {
        //                let url = TextureURL(optographID, side: .Left, size: view.frame.width, face: 0, x: 0, y: 0, d: 1)
        //                self?.imageView.kf_setImageWithURL(NSURL(string: url)!)
        //            } else {
        //                let url = TextureURL(optographID, side: .Left, size: 0, face: 0, x: 0, y: 0, d: 1)
        //                if let originalImage = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url) {
        //                    dispatch_async(dispatch_get_main_queue()) {
        //                        imageView.image = originalImage.resized(.Width, value: view.frame.width)
        //                }
        //            }
        //        }
        
    }
    func adjustDescriptionLabel(recognizer:UITapGestureRecognizer) {
        
        let deleteImageSize1 = UIImage(named:"profile_delete_icn")?.size
        
        if !descriptionOpen {
            let maxWidth = self.view.frame.width - 30 - (deleteImageSize1?.width)!
            let maximumLabelSize = CGSizeMake(maxWidth, 9999);
            let expectedSize = self.descriptionLabel.sizeThatFits(maximumLabelSize)
            
            UIView.animateWithDuration(0.3, animations: {
                self.descriptionLabel.frame = CGRectMake(self.whiteBackground.frame.origin.x + 10, self.view.frame.height - self.whiteBackground.frame.height - expectedSize.height - 10, expectedSize.width, expectedSize.height)
                }, completion:{ val in
                    self.descriptionOpen = true
            })
            
        } else {
            UIView.animateWithDuration(0.3, animations: {
                
                self.descriptionLabel.frame = CGRect(x: self.whiteBackground.frame.origin.x + 10,y: self.view.frame.height - self.whiteBackground.frame.height - 30,width: self.view.frame.width - 30 - (deleteImageSize1?.width)!,height: 20)
                }, completion:{ val in
                    self.descriptionOpen = false
            })
        }
    }
    
    func share() {
        let share = DetailsShareViewController()
        share.optographId = optographID
        self.navigationController?.presentViewController(share, animated: true, completion: nil)
    }
    
    func vrIconTouched() {
        let alert = UIAlertController(title:"", message: "Please tilt your phone by 90\u{00B0} to enter VR mode!", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        self.navigationController!.presentViewController(alert, animated: true, completion: nil)
    }
    
    func deleteOpto() {
        
        if SessionService.isLoggedIn {
            let alert = UIAlertController(title:"Are you sure?", message: "Do you really want to delete this 360 image? You cannot undo this.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { _ in
                self.viewModel.deleteOpto()
                self.closeDetailsPage()
                self.imageCache.deleteMp4(self.optographID)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
            
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title:"", message: "Please login to delete this 360 image.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        }
    }
    func closeDetailsPage() {
        
        renderDelegate.dispose()
        imageCache.reset()
        didEndDisplay()
        viewModel.disposable?.dispose()
        
        self.navigationController?.popViewControllerAnimated(true)
        //self.navigationController?.popToRootViewControllerAnimated(false)
    }
    
    func toggleComment() {
        
        let commentPage = CommentTableViewController()
        commentPage.viewModel = viewModel
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
        deleteButton.hidden = true
        gyroTypeBtn.hidden = true
        descriptionLabel.hidden = true
        self.navigationController?.navigationBarHidden = true
    }
    
    func showUI() {
        self.whiteBackground.hidden = false
        self.hideSelectorButton.hidden = false
        //self.gyroButton.hidden = false
        self.littlePlanetButton.hidden = false
        self.isUIHide = false
        deleteButton.hidden = false
        gyroTypeBtn.hidden = false
        descriptionLabel.hidden = false
        self.navigationController?.navigationBarHidden = false
    }
    
    func oneTap(recognizer:UITapGestureRecognizer) {
        if !isUIHide {
            UIView.animateWithDuration(0.4,delay: 0.1, options: .CurveEaseOut, animations: {
                self.whiteBackground.hidden = true
                self.hideSelectorButton.hidden = true
                //self.gyroButton.hidden = true
                self.gyroTypeBtn.hidden = true
                self.deleteButton.hidden = true
                self.littlePlanetButton.hidden = true
                self.descriptionLabel.hidden = true
                self.isUIHide = true
                },completion: nil)
            self.navigationController?.navigationBarHidden = true
        } else {
            UIView.animateWithDuration(0.4,delay: 0.1, options: .CurveEaseOut, animations: {
                self.whiteBackground.hidden = false
                self.hideSelectorButton.hidden = false
                //self.gyroButton.hidden = false
                self.gyroTypeBtn.hidden = false
                self.deleteButton.hidden = false
                self.littlePlanetButton.hidden = false
                self.descriptionLabel.hidden = false
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
    func export() {
        let imageToSaveUrl = "http://bucket.dscvr.com/textures/\(optographID)/placeholder.jpg"
        
        if let url = NSURL(string: imageToSaveUrl) {
            let request = NSURLRequest(URL: url)
            
            SwiftSpinner.show("Exporting 360 image..")
            
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler:{(response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                let asset = ALAssetsLibrary()
                
                let strModel = "RICOH THETA S" as String
                let strMake = "RICOH" as String
                
                let meta:NSDictionary = [kCGImagePropertyTIFFModel as String :strModel,kCGImagePropertyTIFFMake as String:strMake]
                
                let source:CGImageSourceRef = CGImageSourceCreateWithData(data!, nil)!
                let UTI:CFStringRef = CGImageSourceGetType(source)!
                
                let destData = NSMutableData()
                let destination:CGImageDestinationRef = CGImageDestinationCreateWithData(destData, UTI, 1, nil)!
                
                CGImageDestinationAddImageFromSource(destination, source, 0, meta)
                
                CGImageDestinationFinalize(destination)
                
                
                asset.writeImageDataToSavedPhotosAlbum(destData, metadata: meta as [NSObject : AnyObject], completionBlock: { (path:NSURL!, error:NSError!) -> Void in
                    print("meta path >>> \(path)")
                    print("meta error >>> \(error)")
                    
                    SwiftSpinner.hide()
                    
                    if error == nil {
                        self.returnSuccesAlert("Export Completed", stringMessage:"Saved into your Photo Library.")
                    } else {
                        self.returnSuccesAlert("Export Failed", stringMessage:"Please try again.")
                    }
                })
            })
        }
    }
    func returnSuccesAlert(stringTitle:String, stringMessage:String) {
        let alert = UIAlertController(title: stringTitle, message: stringMessage, preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func exportImage() {
        
        let alert = UIAlertController(title: "Export 360 Image", message: "Do you want to export this 360 image?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Export", style: .Default, handler: { _ in
            self.export()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func changeButtonIcon(isGyro:Bool) {
        
        if isGyro {
            gyroTypeBtn.setBackgroundImage(gyroImageActive, forState: .Normal)
        } else {
            gyroTypeBtn.setBackgroundImage(gyroImageInactive, forState: .Normal)
        }
        
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
        
        CoreMotionRotationSource.Instance.stop()
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
        
        if isInsideStory{
            
        }
        else{
            if isStory{
                for nodes in storyNodes{
                    
                    if nodes.story_object_position.count >= 2{
                        let nodeItem = StorytellingObject()
                        
                        let nodeTranslation = SCNVector3Make(Float(nodes.story_object_position[0])!, Float(nodes.story_object_position[1])!, Float(nodes.story_object_position[2])!)
                        let nodeRotation = SCNVector3Make(Float(nodes.story_object_rotation[0])!, Float(nodes.story_object_rotation[1])!, Float(nodes.story_object_rotation[2])!)
                        
                        nodeItem.objectRotation = nodeRotation
                        nodeItem.objectVector3 = nodeTranslation
                        nodeItem.optographID = nodes.story_object_media_additional_data
                        
                        print("node id: \(nodeItem.optographID)")
                        
                        renderDelegate.addNodeFromServer(nodeItem)

                    }
                    
                    
                    print("counts: \(nodes.story_object_position.count)")
                    print("counts: \(nodes.story_object_rotation.count)")
                }
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
    
    func showRotationAlert() {
        rotationAlert = UIAlertController(title: "Rotate counter clockwise", message: "Please rotate your phone counter clockwise by 90 degree.", preferredStyle: .Alert)
        rotationAlert!.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        self.navigationController?.presentViewController(rotationAlert!, animated: true, completion: nil)
    }
    
    func addVectorAndRotation(vector: SCNVector3, rotation: SCNVector3) {
        
    }
    
    func didEnterFrustrum(nodeObject: StorytellingObject, inFrustrum: Bool) {
//        print("nodeObject: \(nodeObject.optographID)")
        
        
        let mediaTime = CACurrentMediaTime()
//        print("mediaTime \(mediaTime)")
        var timeDiff = mediaTime - lastElapsedTime
//        print("timeDiff \(timeDiff)")
        
        
        //thadzNote for marc: pagkatapos nya pumasok dun sa next optograph, di nya madetect yung backpin na nilagay ko
        //gamit yung
        //if self.scnView!.isNodeInsideFrustum(marknode, withPointOfView: self.cameraCrosshair) 
        //condition sa
        //override func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval)
        
        if (last_optographID == nodeObject.optographID) {
            if inFrustrum{
//                print("inFrustrum")
            // reset if difference is above 3 seconds
                if timeDiff > 3.0 {
                    countDown = 3
                    timeDiff = 0.0
                    lastElapsedTime = mediaTime
                }
                
                // per second countdown
                if timeDiff > 1.0  {
                    countDown -= 1
                    print("countdown \(countDown)")
                    lastElapsedTime = mediaTime
                    
                }
                
                
                if countDown == 0 {
                    // reset countdown
                    countDown = 3
                    if inFrustrum{
                        print("inFrustum: \(nodeObject.optographID)")
                        isInsideStory = true
                        
                        //check if node object is equal to home optograph id
                        if nodeObject.optographID == optographID{
                            dispatch_async(dispatch_get_main_queue(), {
                                let cubeImageCache = self.imageCache.getStory(nodeObject.optographID, side: .Left)
                                self.setCubeImageCache(cubeImageCache)
                                
                                for nodes in self.storyNodes{
                                    if nodes.story_object_position.count >= 2{
                                        let nodeItem = StorytellingObject()
                                        
                                        let nodeTranslation = SCNVector3Make(Float(nodes.story_object_position[0])!, Float(nodes.story_object_position[1])!, Float(nodes.story_object_position[2])!)
                                        let nodeRotation = SCNVector3Make(Float(nodes.story_object_rotation[0])!, Float(nodes.story_object_rotation[1])!, Float(nodes.story_object_rotation[2])!)
                                        
                                        nodeItem.objectRotation = nodeRotation
                                        nodeItem.objectVector3 = nodeTranslation
                                        nodeItem.optographID = nodes.story_object_media_additional_data
                                        
                                        print("node id: \(nodeItem.optographID)")
                                        
                                        self.renderDelegate.addNodeFromServer(nodeItem)
                                        
                                    }
                                }
                                
                                self.renderDelegate.removeAllNodes(self.optographID)
                            })
                        }
                            
                        //else move forward and place a back pin at designated vector3
                        else{
                            dispatch_async(dispatch_get_main_queue(), {
                                let cubeImageCache = self.imageCache.getStory(nodeObject.optographID, side: .Left)
                                self.setCubeImageCache(cubeImageCache)
                                
                                self.renderDelegate.removeAllNodes(nodeObject.optographID)
                                self.renderDelegate.addBackPin(self.optographID)
                            })
                        }
                    }
                    else{
//                        print("!inFrustum")
                    }
                }
            }
            else{
//                print("!inFrustrum")
                countDown = 3
            }
            
            
        }
        else{ // this is a new id
            last_optographID = nodeObject.optographID
        }
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
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
import MediaPlayer
import AVKit
import SQLite

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
    var countDown:Int = 2
    var last_optographID:UUID = ""
    private var lastElapsedTime = CACurrentMediaTime() ;
    
    var mp3Timer: NSTimer?
    var progressTimer: NSTimer?
    
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
    var isEditingStory: Bool = false
    var storyID:UUID?
    
    let storyPinLabel = UILabel()
    
    private var isInsideStory: Bool = false
    private var isPlaying: Bool = false
    let fixedTextLabel = UILabel()
    let removeNode = UIButton()
    let cloudQuote = UIImageView()
    let diagonal = ViewWithDiagonalLine()
    
    var playerItem:AVPlayerItem?
    var player:AVPlayer?
    
    var deletablePin: StorytellingObject = StorytellingObject()
    
    var progress = KDCircularProgress()
    var time:Double = 0.01
    
    var showOpto = MutableProperty<Bool>(false)
    
    var blurView = UIVisualEffectView()
    
    required init(optoList:[UUID],storyid:UUID?) {
        
        optographID = optoList[0]
        optographTopPick = optoList
        
        if let sid = storyID {
            storyID = sid
        }
        
        viewModel = DetailsViewModel(optographID: optographID,storyID:storyid)
        
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
        tabController!.delegate = self
        
        let hfov: Float = 40
        combinedMotionManager = CombinedMotionManager(sceneSize: scnView.frame.size, hfov: hfov)
        renderDelegate = CubeRenderDelegate(rotationMatrixSource: combinedMotionManager, width: scnView.frame.width, height: scnView.frame.height, fov: Double(hfov), cubeFaceCount: 2, autoDispose: true,isStory: isStory)
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
        
        self.createStitchingProgressBar()
        
    }
    
    func insertNewNodes(node: StoryChildren) {
        //storyNodes.value.orderedInsert(node, withOrder: .OrderedAscending)
    }
    
    
    private func pushViewer(orientation: UIInterfaceOrientation) {
        
        let viewerViewController = ViewerViewController(orientation: orientation, arrayOfoptograph: optographTopPick as! [UUID] ,selfOptograph:optographID ,nodesData: viewModel.storyNodes.value)
        navigationController?.pushViewController(viewerViewController, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.OptographDetails")
        
        if let rotationSignal = RotationService.sharedInstance.rotationSignal {
            rotationSignal
                .skipRepeats()
                .filter([.LandscapeLeft, .LandscapeRight])
                .take(1)
                .observeOn(UIScheduler())
                .observeNext { [weak self] orientation in self?.pushViewer(orientation) }
        }
        
        whiteBackground.backgroundColor = UIColor.blackColor().alpha(0.60)
        self.view.addSubview(whiteBackground)
        
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .blackColor()
        //descriptionLabel.backgroundColor = UIColor.whiteColor()
        descriptionLabel.font = UIFont(name: "MerriweatherLight",size: 12)
        descriptionLabel.textAlignment = NSTextAlignment.Center
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
        let deleteImageSize1 = UIImage(named:"profile_delete_icn")?.size
        
        descriptionLabel.frame = CGRect(x: whiteBackground.frame.origin.x + 10,y: view.frame.height - whiteBackground.frame.height - 40,width: view.frame.width - 30 - (deleteImageSize1?.width)!,height: 20)
        
        
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
        //descriptionLabel.rac_text <~ viewModel.text
        viewModel.text.producer.startWithNext{ val in
            if val != "" {
                self.descriptionLabel.backgroundColor = UIColor.whiteColor()
            }
            self.descriptionLabel.text = val
            self.descriptionLabel.sizeToFit()
            self.descriptionLabel.frame = CGRect(origin: self.descriptionLabel.frame.origin, size: CGSize(width: self.descriptionLabel.frame.size.width + 10.0, height: self.descriptionLabel.frame.size.height + 2))
        
        }
//        let maximumLabelSize = CGSizeMake(view.width, 9999);
//        let expectedSize = self.descriptionLabel.sizeThatFits(maximumLabelSize)
//        descriptionLabel.frame = CGRect(origin: descriptionLabel.frame.origin, size: <#T##CGSize#>)
        
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
        
        navigationItem.rightBarButtonItems = [vrButton]
        
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
            deleteButton.align(.AboveMatchingRight, relativeTo: whiteBackground, padding: 10, width: (deleteImageSize?.width)! + 5, height: (deleteImageSize?.height)! + 5)
            
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
        
        let cloudQuoteImage = UIImage(named: "cloud_quote")
        cloudQuote.frame = CGRect(origin: self.view.center, size: (cloudQuoteImage?.size)!)
        cloudQuote.image = cloudQuoteImage
        cloudQuote.hidden = true
        
//        diagonal.frame = CGRectMake(0, 0, 0, 0)
//        diagonal.backgroundColor = UIColor.clearColor()
        
//        self.view.addSubview(diagonal)
        
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
        
        if viewModel.optographBox.model.isPublished && !viewModel.optographBox.model.isUploading {
            let share = DetailsShareViewController()
            share.optographId = optographID
            self.navigationController?.presentViewController(share, animated: true, completion: nil)
            
//            Async.main { [weak self] in
//                let textToShare = "Check out this awesome 360 images"
//                let baseURL = Env == .Staging ? "wow.dscvr.com" : "wow.dscvr.com"
//                let shareUrl = NSURL(string: "http://\(baseURL)/\(self!.viewModel.shareAlias)")!
//                let activityVC = UIActivityViewController(activityItems: [textToShare, shareUrl], applicationActivities:nil)
//                activityVC.excludedActivityTypes = [UIActivityTypeAirDrop,UIActivityTypePrint, UIActivityTypePostToWeibo, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo]
//                
//                self?.navigationController?.presentViewController(activityVC, animated: true, completion: nil)
//            }
        } else {
//            let alert = UIAlertController(title:"Oops! You haven't uploaded yet!", message: "Please go to your Profile > Images and upload your 360 photo!", preferredStyle: .Alert)
//            
//            let imageView = UIImageView(frame: CGRectMake(20, 40, 100, 100))
//            alert.view.addSubview(imageView)
//            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
//            
//            let url = TextureURL(optographID, side: .Left, size: 0, face: 0, x: 0, y: 0, d: 1)
//            if let originalImage = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url) {
//                dispatch_async(dispatch_get_main_queue()) {
//                    imageView.image = originalImage.resized(.Width, value: 40)
//                    self.navigationController?.presentViewController(alert, animated: true, completion: nil)
//                }
//            }
            
            let customAlertView = NYAlertViewController()
            let url = TextureURL(optographID, side: .Left, size: 0, face: 0, x: 0, y: 0, d: 1)
            let imageOpto = UIImageView()
            if let originalImage = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url) {
                dispatch_async(dispatch_get_main_queue()) {
                    imageOpto.image = originalImage.resized(.Width, value: self.view.frame.width - 100)
                }
            }
            
            customAlertView.alertViewContentView = imageOpto
            customAlertView.title = "Oops! You haven't uploaded yet!"
            customAlertView.message = "Please go to your Profile > Images and upload your 360 photo!"
            customAlertView.swipeDismissalGestureEnabled = true
            customAlertView.backgroundTapDismissalGestureEnabled = true
            
            let cancelAction = NYAlertAction(
                title: "Ok",
                style: .Cancel,
                handler: { (action: NYAlertAction!) -> Void in
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            )
            customAlertView.addAction(cancelAction)
            self.navigationController?.presentViewController(customAlertView, animated: true, completion: nil)
        }
        
    }
    
    func vrIconTouched() {
        let alert = UIAlertController(title:"", message: "Please tilt your phone by 90\u{00B0} to enter VR mode!", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        self.navigationController!.presentViewController(alert, animated: true, completion: nil)
    }
    
    func createStitchingProgressBar() {
        
        self.progress = KDCircularProgress(frame: CGRect(x: (self.view.width/2) - 15, y: (self.view.height/2) - 15, width: 30, height: 30))
        self.progress.progressThickness = 0.3
        self.progress.trackThickness = 0.5
        self.progress.clockwise = true
        self.progress.startAngle = 360
        self.progress.gradientRotateSpeed = 2
        self.progress.roundedCorners = true
        self.progress.glowMode = .Forward
        self.progress.setColors(UIColor(hex:0xFF5E00) ,UIColor(hex:0xFF7300), UIColor(hex:0xffbc00))
        self.progress.hidden = true
        self.view.addSubview(self.progress)
    }
    
    func deleteOpto() {
        
        if SessionService.isLoggedIn {
            if isStory {
                let alert = UIAlertController(title:"Are you sure?", message: "Do you really want to delete this story? You cannot undo this.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { _ in
                    self.viewModel.deleteStories(self.storyID!)
                        .on(failed : { [weak self] _ in
                            
                            let alert = UIAlertController(title:"Error!", message: "Deleting failed! Please try again.", preferredStyle: .Alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                            self?.navigationController!.presentViewController(alert, animated: true, completion: nil)
                            },completed: { [weak self] _ in
                                self?.closeDetailsPage()
                    }).start()
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
                self.navigationController!.presentViewController(alert, animated: true, completion: nil)
            
            } else {
                let alert = UIAlertController(title:"Are you sure?", message: "Do you really want to delete this 360 image? You cannot undo this.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { _ in
                    self.viewModel.deleteOpto()
                    self.closeDetailsPage()
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
                self.navigationController!.presentViewController(alert, animated: true, completion: nil)
            }
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
        
        if viewModel.optographBox.model.isPublished && !viewModel.optographBox.model.isUploading {
            let commentPage = CommentTableViewController()
            commentPage.viewModel = viewModel
            self.navigationController?.presentViewController(commentPage, animated: true, completion: nil)
        } else {
            
            let customAlertView = NYAlertViewController()
            let url = TextureURL(optographID, side: .Left, size: 0, face: 0, x: 0, y: 0, d: 1)
            let imageOpto = UIImageView()
            if let originalImage = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url) {
                dispatch_async(dispatch_get_main_queue()) {
                    imageOpto.image = originalImage.resized(.Width, value: self.view.frame.width - 100)
                }
            }
            
            customAlertView.alertViewContentView = imageOpto
            customAlertView.title = "Oops! You haven't uploaded yet!"
            customAlertView.message = "Please go to your Profile > Images and upload your 360 photo!"
            customAlertView.swipeDismissalGestureEnabled = true
            customAlertView.backgroundTapDismissalGestureEnabled = true
            
            let cancelAction = NYAlertAction(
                title: "Ok",
                style: .Cancel,
                handler: { (action: NYAlertAction!) -> Void in
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            )
            customAlertView.addAction(cancelAction)
            self.navigationController?.presentViewController(customAlertView, animated: true, completion: nil)
        }
    }
    
    func pinchGesture(recognizer:UIPinchGestureRecognizer) {
        
        if let view = recognizer.view {
            if recognizer.state == UIGestureRecognizerState.Began {
                hideUI()
                if transformBegin == nil {
                    transformBegin = CGAffineTransformScale(view.transform,recognizer.scale, recognizer.scale)
                }
            } else if recognizer.state == UIGestureRecognizerState.Changed {
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
        
        Mixpanel.sharedInstance().track("View.OptographDetails", properties: ["optograph_id": viewModel.optographId, "optograph_description" : viewModel.text.value])
        
        Mixpanel.sharedInstance().track("View.OptographDetails", properties: ["optograph_id": "", "optograph_description" : ""])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tabController!.disableScrollView()
        
        CoreMotionRotationSource.Instance.start()
        RotationService.sharedInstance.rotationEnable()
        
        updateNavbarAppear()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        CoreMotionRotationSource.Instance.stop()
        RotationService.sharedInstance.rotationDisable()
        tabController!.enableScrollView()
        
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        
        mp3Timer?.invalidate()
        self.progressTimer?.invalidate()
        
        
        if player != nil{
            player!.pause()
            player = nil
        }
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
                for node in viewModel.storyNodes.value {
                    let objectPosition = node.objectPosition.characters.split{$0 == ","}.map(String.init)
                    let objectRotation = node.objectRotation.characters.split{$0 == ","}.map(String.init)
                    
                    if node.mediaType == "FXTXT"{
                        
                        print("MEDIATYPE: FXTXT")
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            
                            self.fixedTextLabel.text = node.mediaAdditionalData
                            self.fixedTextLabel.textColor = UIColor.blackColor()
                            self.fixedTextLabel.font = UIFont(name: "BigNoodleTitling", size: 22.0)
                            self.fixedTextLabel.sizeToFit()
                            self.fixedTextLabel.frame = CGRect(x: 10.0, y: self.view.frame.size.height - 135.0, width: self.fixedTextLabel.frame.size.width + 5.0, height: self.fixedTextLabel.frame.size.height + 5.0)
                            self.fixedTextLabel.backgroundColor = UIColor(0xffbc00)
                            self.fixedTextLabel.textAlignment = NSTextAlignment.Center
                            self.view.addSubview((self.fixedTextLabel))
                            self.removeNode.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                            self.removeNode.backgroundColor = UIColor.blackColor()
                            self.removeNode.center = CGPoint(x: (self.view.center.x) - 10, y: (self.view.center.y) - 10)
                            self.removeNode.setImage(UIImage(named: "close_icn"), forState: UIControlState.Normal)
                            self.removeNode.addTarget(self, action: #selector(self.removePin), forControlEvents: UIControlEvents.TouchUpInside)
                            self.removeNode.hidden = true
                            self.view.addSubview((self.removeNode))
                        })
                    } else if node.mediaType == "MUS"{
                        print("MEDIATYPE: MUS")
                        
                        let url = NSURL(string: "https://bucket.dscvr.com" + node.objectMediaFileUrl)
                        //let url = NSURL(string: node.objectMediaFileUrl)
                        print("url:",url)
                        
                        if let returnPath:String = self.imageCache.insertStoryFile(url, file: nil, fileName: node.objectMediaFilename) {
                            print(">>>>>>",returnPath)
                            
                            if returnPath != "" {
                                print(returnPath)
                                self.playerItem = AVPlayerItem(URL: NSURL(fileURLWithPath: returnPath))
                                self.player = AVPlayer(playerItem: self.playerItem!)
                                self.player?.rate = 1.0
                                self.player?.volume = 1.0
                                self.player!.play()
                                
                                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.playerItemDidReachEnd), name: AVPlayerItemDidPlayToEndTimeNotification, object: self.player!.currentItem)
                            } else {
                                self.mp3Timer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(self.checkMp3), userInfo: ["FileUrl":"https://bucket.dscvr.com" + node.objectMediaFileUrl,"FileName":node.objectMediaFilename], repeats: true)
                            }
                        }
                    } else {
                        if objectPosition.count >= 2{
                            let nodeItem = StorytellingObject()
                            
                            let nodeTranslation = SCNVector3Make(Float(objectPosition[0])!, Float(objectPosition[1])!, Float(objectPosition[2])!)
                            let nodeRotation = SCNVector3Make(Float(objectRotation[0])!, Float(objectRotation[1])!, Float(objectRotation[2])!)
                            
                            nodeItem.objectRotation = nodeRotation
                            nodeItem.objectVector3 = nodeTranslation
                            nodeItem.optographID = node.mediaAdditionalData
                            nodeItem.objectType = node.mediaType
                            
                            print("node id: \(nodeItem.optographID)")
                            print("nodes: \(node.mediaType)")
                            
                            self.renderDelegate.addNodeFromServer(nodeItem)
                        }
                        
                    }
                    print("counts: \(objectPosition.count)")
                    print("counts: \(objectRotation.count)")
                    
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
    
    func checkMp3(timer:NSTimer) {
        
        let userInfo = timer.userInfo as! Dictionary<String, AnyObject>
        
        let fileUrl:String = (userInfo["FileUrl"] as! String)
        let fileName:String = (userInfo["FileName"] as! String)
        
        let url = NSURL(string: "https://bucket.dscvr.com" + fileUrl)
        print("url:",url)
        
        if let returnPath:String = imageCache.insertStoryFile(url, file: nil, fileName: fileName) {
            
            if returnPath != "" {
                print(returnPath)
                playerItem = AVPlayerItem(URL: NSURL(fileURLWithPath: returnPath))
                self.player = AVPlayer(playerItem: self.playerItem!)
                self.player?.rate = 1.0
                self.player?.volume = 1.0
                self.player!.play()
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.playerItemDidReachEnd), name: AVPlayerItemDidPlayToEndTimeNotification, object: self.player!.currentItem)
                mp3Timer?.invalidate()
            }
        }
    }
    
    func showRotationAlert() {
        rotationAlert = UIAlertController(title: "Rotate counter clockwise", message: "Please rotate your phone counter clockwise by 90 degree.", preferredStyle: .Alert)
        rotationAlert!.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        self.navigationController?.presentViewController(rotationAlert!, animated: true, completion: nil)
    }
    func addVectorAndRotation(vector: SCNVector3, rotation: SCNVector3) {
        
    }
    
    func playPinMusic(nodeObject: StorytellingObject){
        let nameArray = nodeObject.optographID.componentsSeparatedByString(",")
        
        let url = NSURL(string: "https://bucket.dscvr.com" + nameArray[0])
        print(url)
        playerItem = AVPlayerItem(URL: url!)
        player = AVPlayer(playerItem: playerItem!)
        player?.rate = 1.0
        player?.volume = 1.0
        player!.play()
    }
    
    func playerItemDidReachEnd(notification: NSNotification){
        player!.seekToTime(kCMTimeZero)
        player!.play()
    }
    
    func showOptograph(nodeObject: StorytellingObject){
        print("NODE NAME: \(nodeObject.optographID)")
        //check if node object is equal to home optograph id
        let nameArray = nodeObject.optographID.componentsSeparatedByString(",")
        if nameArray[0] == self.optographID {
            dispatch_async(dispatch_get_main_queue(), {
                let cubeImageCache = self.imageCache.getStory(self.optographID, side: .Left)
                self.setCubeImageCache(cubeImageCache)
                self.renderDelegate.centerCameraPosition()
                self.renderDelegate.removeAllNodes(self.optographID)
                self.renderDelegate.removeMarkers()
                
                for node in self.viewModel.storyNodes.value {
                    let objectPosition = node.objectPosition.characters.split{$0 == ","}.map(String.init)
                    let objectRotation = node.objectRotation.characters.split{$0 == ","}.map(String.init)
                    
                    if objectPosition.count >= 2{
                        
                        let nodeItem = StorytellingObject()
                        
                        let nodeTranslation = SCNVector3Make(Float(objectPosition[0])!, Float(objectPosition[1])!, Float(objectPosition[2])!)
                        let nodeRotation = SCNVector3Make(Float(objectRotation[0])!, Float(objectRotation[1])!, Float(objectRotation[2])!)
                        
                        nodeItem.objectRotation = nodeRotation
                        nodeItem.objectVector3 = nodeTranslation
                        nodeItem.objectType = node.mediaType
                        
                        if node.mediaType == "MUS"{
                            nodeItem.optographID = node.objectMediaFileUrl
                        }
                            
                        else if node.mediaType == "NAV" || node.mediaType == "TXT"{
                            nodeItem.optographID = node.mediaAdditionalData
                            self.renderDelegate.addNodeFromServer(nodeItem)
                        }
                        
                        
                        
                    }
                }
            })
        }
            //else move forward and place a back pin at designated vector3
        else{
            dispatch_async(dispatch_get_main_queue(), {
                let nameArray = nodeObject.optographID.componentsSeparatedByString(",")
                
                let cubeImageCache = self.imageCache.getStory(nameArray[0], side: .Left)
                self.setCubeImageCache(cubeImageCache)
                self.renderDelegate.removeMarkers()
                self.renderDelegate.centerCameraPosition()

                
                self.renderDelegate.removeAllNodes(nodeObject.optographID)
                self.renderDelegate.addBackPin(self.optographID)
                
            })
        }
    }
    
    func showText(nodeObject: StorytellingObject){
        let nameArray = nodeObject.optographID.componentsSeparatedByString(",")
        print("TEXT: \(nameArray[0])")
        
        dispatch_async(dispatch_get_main_queue(), {
            if !self.self.blurView.isDescendantOfView(self.view) {
                
                self.storyPinLabel.text = nameArray[0]
                self.storyPinLabel.frame = CGRect(x : 0, y: 0, width: self.storyPinLabel.frame.size.width + 40, height: self.storyPinLabel.frame.size.height + 30)
                self.storyPinLabel.textColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
                self.storyPinLabel.font = UIFont(name: "MerriweatherLight", size: 18.0)
                self.storyPinLabel.sizeToFit()
                self.storyPinLabel.textAlignment = NSTextAlignment.Center
                
                let blurEffect = UIBlurEffect(style: .Light)
                self.blurView = UIVisualEffectView(effect: blurEffect)
                self.blurView.clipsToBounds = true
                self.blurView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.60)
                self.blurView.layer.borderColor = UIColor.blackColor().colorWithAlphaComponent(0.4).CGColor
                self.blurView.layer.borderWidth = 1.0
                self.blurView.layer.cornerRadius = 6.0
                self.blurView.frame = CGRect(x : 0, y: 0, width: self.storyPinLabel.frame.size.width + 20, height: self.storyPinLabel.frame.size.height + 20)
                self.storyPinLabel.center.x = self.blurView.center.x
                self.storyPinLabel.center.y = self.blurView.center.y
                
                self.blurView.center = CGPoint(x: self.view.center.x + 50, y: self.view.center.y - 50)
                self.blurView.contentView.addSubview(self.storyPinLabel)
                
                self.view.addSubview(self.blurView)
            }
        })
    }
    
    func playPinAudio(nodeObject: StorytellingObject){
        dispatch_async(dispatch_get_main_queue(), {
            if !self.isPlaying{
                self.isPlaying = true
                let url = NSURL(string: "http://jumpserver.mine.nu/albatroz.mp3")
                self.playerItem = AVPlayerItem(URL: url!)
                self.player=AVPlayer(playerItem: self.playerItem!)
                self.player?.rate = 1.0
                self.player?.volume = 1.0
                self.player!.play()
            }
        })
    }
    
    func showRemovePinButton(nodeObject: StorytellingObject){
        
        dispatch_async(dispatch_get_main_queue(), {
//            let removePinButton = UIButton(frame: CGRect(x: 0, y: 0, width: 20.0, height: 20.0))
//            removePinButton.center = CGPoint(x: self.view.center.x - 10, y: self.view.center.y + 10)
//            removePinButton.backgroundColor = UIColor.blackColor()
//            removePinButton.addTarget(self, action: #selector(self.removePin), forControlEvents: UIControlEvents.TouchUpInside)
//            self.view.addSubview(removePinButton)
            
            self.deletablePin = nodeObject
            
            self.removeNode.hidden = false
        })
        
        
    }
  
    func removePin(){
        
//        nodeData.optographID + "," + nodeData.objectType
//        let predicate = NSPredicate(format: "story_object_media_description != %@", "story bgm")
        
        let nameArray = deletablePin.optographID.componentsSeparatedByString(",")
        
        
//        storyNodes.producer.startWithNext { [weak self] nodes in
//            let filteredArray = nodes.filter { $0.mediaAdditionalData != nameArray[0] }
//            print("filteredArray: \(filteredArray.count)")
//            print("deletable ID: \(nameArray[0])")
//            print(">>>>>",(self?.deletablePin.optographID)!)
//            
//            self?.renderDelegate.removeAllNodes((self?.deletablePin.optographID)!)
//            //self?.storyNodes = filteredArray
//        }
        
        let nodes = viewModel.storyNodes.value
        
        let filteredArray = nodes.filter { $0.mediaAdditionalData != nameArray[0] }
        print("filteredArray: \(filteredArray.count)")
        print("deletable ID: \(nameArray[0])")
        
        self.renderDelegate.removeAllNodes(self.deletablePin.optographID)
        
    }
    
    func isInButtonCamera(inFrustrum: Bool){
        
        if !inFrustrum{
            dispatch_async(dispatch_get_main_queue(), {
                self.removeNode.hidden = true
            })
        }
    }
    
    func putProgress() {
        
        time += 0.01
        self.progress.hidden = false
        self.progress.angle = 180 * time
        
        if time >= 2 {
            stopProgress()
            showOpto.value = true
        }
    }
    
    func stopProgress() {
        
        progressTimer?.invalidate()
        time = 0.01
        self.progress.angle = 0
        self.progress.hidden = true
        
    }
    
    func didEnterFrustrum(nodeObject: StorytellingObject, inFrustrum: Bool) {
        
        if !inFrustrum {
            countDown = 2
            dispatch_async(dispatch_get_main_queue(), {
                self.storyPinLabel.text = ""
                self.storyPinLabel.backgroundColor = UIColor.clearColor()
                self.cloudQuote.hidden = true
                self.stopProgress()
                self.blurView.removeFromSuperview()
            })
            return
            
        }
        
        print("nodeObject >>",nodeObject.optographID.componentsSeparatedByString(","))
        
        
        let mediaTime = CACurrentMediaTime()
        var timeDiff = mediaTime - lastElapsedTime
        
        if (last_optographID == nodeObject.optographID) {
            
            // reset if difference is above 3 seconds
            
            if timeDiff > 3.0 {
                countDown = 2
                timeDiff = 0.0
                lastElapsedTime = mediaTime
            }
            
            
            let nameArray = nodeObject.optographID.componentsSeparatedByString(",")
            
            if nameArray[1] == "TXT" {
                self.showText(nodeObject)
                return
            }
            
            // per second countdown
            if timeDiff > 1.0  {
                countDown -= 1
                lastElapsedTime = mediaTime
                    
                dispatch_async(dispatch_get_main_queue(), {
                    self.storyPinLabel.text = ""
                    if self.countDown == 2 {
                        if self.progressTimer == nil {
                            self.progressTimer = NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector:#selector(self.putProgress), userInfo: nil, repeats: true)
                        } else if !(self.progressTimer?.valid)! {
                            self.progressTimer = NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector:#selector(self.putProgress), userInfo: nil, repeats: true)
                        }
                        
                        self.showOpto.producer.skip(1).startWithNext{ val in
                            if val {
                                if nameArray[1] == "NAV" || nameArray[1] == "Image"{
                                    self.showOptograph(nodeObject)
                                }
                            }
                        }
                    }
                })
            }
                
            if countDown == 0 {
                countDown = 2
                    
                dispatch_async(dispatch_get_main_queue(), {
                    self.storyPinLabel.text = ""
                    self.isPlaying = false
                })
                
                isInsideStory = true
            }
        } else{
            last_optographID = nodeObject.optographID
        }
    }
    
}

class SpeechBubble: UIView {
    
    var color:UIColor = UIColor.grayColor()
    var text: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required convenience init(withColor frame: CGRect, color:UIColor? = .None) {
        self.init(frame: frame)
        
        let label = UILabel(frame: frame)
        label.text = text
        label.textAlignment = .Center
        label.textColor = UIColor.whiteColor()
        addSubview(label)
        
        if let color = color {
            self.color = color
        }
    }
    
    override func drawRect(rect: CGRect) {
        
        let rounding:CGFloat = rect.width * 0.02
        
        //Draw the main frame
        
        let bubbleFrame = CGRect(x: 0, y: 0, width: rect.width, height: rect.height * 2 / 3)
        let bubblePath = UIBezierPath(roundedRect: bubbleFrame, byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSize(width: rounding, height: rounding))
        
        //Color the bubbleFrame
        
        color.setStroke()
        color.setFill()
        bubblePath.stroke()
        bubblePath.fill()
        
        //Add the point
        
        let context = UIGraphicsGetCurrentContext()
        
        //Start the line
        
        CGContextBeginPath(context)
        CGContextMoveToPoint(context, CGRectGetMinX(bubbleFrame) + bubbleFrame.width * 1/3, CGRectGetMaxY(bubbleFrame))
        
        //Draw a rounded point
        
        CGContextAddArcToPoint(context, CGRectGetMaxX(rect) * 1/3, CGRectGetMaxY(rect), CGRectGetMaxX(bubbleFrame), CGRectGetMinY(bubbleFrame), rounding)
        
        //Close the line
        
        CGContextAddLineToPoint(context, CGRectGetMinX(bubbleFrame) + bubbleFrame.width * 2/3, CGRectGetMaxY(bubbleFrame))
        CGContextClosePath(context)
        
        //fill the color
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillPath(context);
    }
}

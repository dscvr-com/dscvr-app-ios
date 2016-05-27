//
//  SaveThetaViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 4/12/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Result
import KMPlaceholderTextView
import Mixpanel
import Async
import AVFoundation
import SceneKit
import ObjectMapper
import FBSDKLoginKit
import TwitterKit
import SpriteKit
import SwiftyUserDefaults

class SaveThetaViewController: UIViewController, RedNavbar {
    
    private let viewModel: SaveViewModel
    
    private var touchRotationSource: TouchRotationSource!
    private var renderDelegate: SphereRenderDelegate!
    private var scnView: SCNView!
    
    // subviews
    private let scrollView = ScrollView()
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    private let dragTextView = UILabel()
    private let dragIconView = UILabel()
    private let locationView: LocationView
    private let textInputView = UITextView()
    private let textPlaceholderView = UILabel()
    private let shareBackgroundView = UIView()
    private let facebookSocialButton = SocialButton()
    private let twitterSocialButton = SocialButton()
    private let instagramSocialButton = SocialButton()
    private let moreSocialButton = SocialButton()
    private var placeholderImage: SKTexture?
    //private var tabView = TabView()
    private var cameraButton = TButton()
    private var postLater = TButton()
    
    private let readyNotification = NotificationSignal<Void>()
    
    required init(thetaImage:UIImage) {
        
        let recorderCleanup = SignalProducer<UIImage, NoError> { sink, disposable in
            
            sink.sendNext(thetaImage)
            sink.sendCompleted()
        }
        
        let (placeholderSignal, placeholderSink) = Signal<UIImage, NoError>.pipe()
        
        viewModel = SaveViewModel(placeholderSignal: placeholderSignal, readyNotification: readyNotification)
        
        locationView = LocationView(isOnline: viewModel.isOnline)
        
        super.init(nibName: nil, bundle: nil)
        
        recorderCleanup
            .startOn(QueueScheduler(queue: dispatch_queue_create("recorderQueue", DISPATCH_QUEUE_SERIAL)))
            .on(event: { event in
                placeholderSink.action(event)
            })
            .map { SKTexture(image: self.resizeImage($0, newWidth: 2513)) }
            .observeOnMain()
            .on(
                next: { [weak self] image in
                    if let renderDelegate = self?.renderDelegate {
                        renderDelegate.texture = image
                    } else {
                        self?.placeholderImage = image
                    }
                },
                completed: { [weak self] in
                    ApiService<EmptyResponse>.get("completed").start()
                    self?.viewModel.stitcherFinished.value = true
                }
            )
            .start()
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, 362))
        image.drawInRect(CGRectMake(0, 0, newWidth, 362))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if SessionService.isLoggedIn {
            readyNotification.notify(())
        }
        
        title = "SAVE THE MOMENT"

        
        var privateButton = UIImage(named: "privacy_me")
        var publicButton = UIImage(named: "privacy_world")
        var cancelButton = UIImage(named: "camera_back_button")
        
        privateButton = privateButton?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        publicButton = publicButton?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        cancelButton = cancelButton?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: cancelButton, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.cancel))
        
        
        viewModel.isPrivate.producer.startWithNext { [weak self] isPrivate in
            if let strongSelf = self {
                
                strongSelf.navigationItem.rightBarButtonItem = UIBarButtonItem(image: isPrivate ? privateButton : publicButton, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(strongSelf.togglePrivate))
            }
        }
        
        view.backgroundColor = .whiteColor()
        
        let scnFrame = CGRect(x: 0, y: 0, width: view.frame.width, height: 0.46 * view.frame.width)
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: scnFrame, options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
        } else {
            scnView = SCNView(frame: scnFrame)
        }
        
        let hfov: Float = 80
        
        touchRotationSource = TouchRotationSource(sceneSize: scnView.frame.size, hfov: hfov)
        touchRotationSource.dampFactor = 0.9999
        touchRotationSource.phiDamp = 0.003
        
        renderDelegate = SphereRenderDelegate(rotationMatrixSource: touchRotationSource, width: scnView.frame.width, height: scnView.frame.height, fov: Double(hfov))
        
        scnView.scene = renderDelegate.scene
        scnView.delegate = renderDelegate
        scnView.backgroundColor = .blackColor()
        scnView.playing = UIDevice.currentDevice().deviceType != .Simulator
        scrollView.addSubview(scnView)
        
        renderDelegate.texture = placeholderImage
        
        blurView.frame = scnView.frame
        
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = blurView.frame
        gradientMaskLayer.colors = [UIColor.blackColor().CGColor, UIColor.clearColor().CGColor, UIColor.clearColor().CGColor, UIColor.blackColor().CGColor]
        gradientMaskLayer.locations = [0.0, 0.4, 0.6, 1.0]
        gradientMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientMaskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        blurView.layer.addSublayer(gradientMaskLayer)
        blurView.layer.mask = gradientMaskLayer
        scrollView.addSubview(blurView)
        
        let dragText = "Move the image to select your favorite spot"
        let dragTextWidth = calcTextWidth(dragText, withFont: .displayOfSize(13, withType: .Light))
        dragTextView.text = dragText
        dragTextView.textAlignment = .Center
        dragTextView.font = UIFont.displayOfSize(13, withType: .Light)
        dragTextView.textColor = .whiteColor()
        dragTextView.layer.shadowColor = UIColor.blackColor().CGColor
        dragTextView.layer.shadowRadius = 5
        dragTextView.layer.shadowOffset = CGSizeZero
        dragTextView.layer.shadowOpacity = 1
        dragTextView.layer.masksToBounds = false
        dragTextView.layer.shouldRasterize = true
        dragTextView.frame = CGRect(x: view.frame.width / 2 - dragTextWidth / 2 + 15, y: 0.46 * view.frame.width - 40, width: dragTextWidth, height: 20)
        scrollView.addSubview(dragTextView)
        
        dragIconView.text = String.iconWithName(.DragImage)
        dragIconView.font = UIFont.iconOfSize(20)
        dragIconView.textColor = .whiteColor()
        dragIconView.frame = CGRect(x: -30, y: 0, width: 20, height: 20)
        dragTextView.addSubview(dragIconView)
        
        locationView.didSelectLocation = { [weak self] placeID in
            self?.viewModel.placeID.value = placeID
        }
        scrollView.addSubview(locationView)
        
        textPlaceholderView.font = UIFont.textOfSize(12, withType: .Regular)
        textPlaceholderView.text = "Tell something about what you see..."
        textPlaceholderView.textColor = UIColor.DarkGrey.alpha(0.4)
        textPlaceholderView.rac_hidden <~ viewModel.text.producer.map(isNotEmpty)
        textInputView.addSubview(textPlaceholderView)
        
        textInputView.font = UIFont.textOfSize(12, withType: .Regular)
        textInputView.textColor = UIColor(0x4d4d4d)
        textInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        textInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        textInputView.returnKeyType = .Done
        //        textInputView.keyboardType = .Twitter
        textInputView.delegate = self
        textInputView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 14, right: 0)
        textInputView.textContainerInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        textInputView.rac_textSignal().toSignalProducer().startWithNext { [weak self] val in
            self?.viewModel.text.value = val as! String
        }
        textInputView.removeConstraints(textInputView.constraints)
        scrollView.addSubview(textInputView)
        
        shareBackgroundView.backgroundColor = UIColor(0xfbfbfb)
        shareBackgroundView.layer.borderWidth = 1
        shareBackgroundView.layer.borderColor = UIColor(0xe6e6e6).CGColor
        scrollView.addSubview(shareBackgroundView)
        
        //facebookSocialButton.icon = String.iconWithName(.Facebook)
        facebookSocialButton.text = "Facebook"
        facebookSocialButton.color = UIColor(0x3b5998)
        facebookSocialButton.userInteractionEnabled = true
        facebookSocialButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SaveThetaViewController.tapFacebookSocialButton)))
        shareBackgroundView.addSubview(facebookSocialButton)
        
        viewModel.postFacebook.producer.startWithNext { [weak self] toggled in
            self?.facebookSocialButton.state = toggled ? .Selected : .Unselected
            self?.facebookSocialButton.icon2 = toggled ? UIImage(named:"facebook_save_active")! : UIImage(named:"facebook_save_inactive")!
        }
        
        twitterSocialButton.text = "Twitter"
        twitterSocialButton.color = UIColor(0x55acee)
        twitterSocialButton.userInteractionEnabled = true
        twitterSocialButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SaveThetaViewController.tapTwitterSocialButton)))
        shareBackgroundView.addSubview(twitterSocialButton)
        
        viewModel.postTwitter.producer.startWithNext { [weak self] toggled in
            self?.twitterSocialButton.state = toggled ? .Selected : .Unselected
            self?.twitterSocialButton.icon2 = toggled ? UIImage(named:"twitter_save_active")! : UIImage(named:"twitter_save_inactive")!
        }
        
        instagramSocialButton.text = "Instagram"
        instagramSocialButton.color = UIColor(0x9b6954)
        instagramSocialButton.userInteractionEnabled = true
        instagramSocialButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SaveThetaViewController.tapInstagramSocialButton)))
        shareBackgroundView.addSubview(instagramSocialButton)
        
        viewModel.postInstagram.producer.startWithNext { [weak self] toggled in
            self?.instagramSocialButton.state = toggled ? .Selected : .Unselected
            self?.instagramSocialButton.icon2 = toggled ? UIImage(named:"instagram_save_active")! : UIImage(named:"instagram_save_inactive")!
        }
        
        moreSocialButton.icon2 = UIImage(named:"more_save_active")!
        moreSocialButton.text = "More"
        moreSocialButton.rac_userInteractionEnabled <~ viewModel.isReadyForSubmit.producer.combineLatestWith(viewModel.isOnline.producer).map(and)
        moreSocialButton.rac_alpha <~ viewModel.isReadyForSubmit.producer.mapToTuple(1, 0.2)
        moreSocialButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SaveThetaViewController.tapMoreSocialButton)))
        shareBackgroundView.addSubview(moreSocialButton)
        
        scrollView.scnView = scnView
        view.addSubview(scrollView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SaveThetaViewController.dismissKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
    
        cameraButton.icon = UIImage(named:"upload_now_btn")!
        cameraButton.addTarget(self, action: #selector(readyToSubmit), forControlEvents: .TouchUpInside)
        scrollView.addSubview(cameraButton)
        
        
        postLater.icon = UIImage(named:"post_later")!
        postLater.addTarget(self, action: #selector(postLaterAction), forControlEvents: .TouchUpInside)
        scrollView.addSubview(postLater)
        
        viewModel.isReadyForSubmit.producer.startWithNext { [weak self] isReady in
            self!.cameraButton.loading = !isReady
            self!.postLater.loading = !isReady
            if isReady {
                self?.cameraButton.icon = UIImage(named:"upload_next")!
            }
        }
        
        tabController!.delegate = self
    }
    func readyToSubmit(){
        if viewModel.isReadyForSubmit.value {
            submit(true)
        }
    }
    func postLaterAction(){
        if viewModel.isReadyForSubmit.value {
            submit(false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let contentHeight = 0.46 * view.frame.width + 85 + 68 + 120 + 126
        let scrollEnabled = contentHeight > view.frame.height
        scrollView.contentSize = CGSize(width: view.frame.width, height: scrollEnabled ? contentHeight : view.frame.height)
        scrollView.scrollEnabled = scrollEnabled
        
        scrollView.fillSuperview()
        locationView.alignAndFillWidth(align: .UnderCentered, relativeTo: scnView, padding: 0, height: 68)
        textInputView.alignAndFillWidth(align: .UnderCentered, relativeTo: locationView, padding: 0, height: 85)
        textPlaceholderView.anchorInCorner(.TopLeft, xPad: 16, yPad: 7, width: 250, height: 20)
        
        if scrollEnabled {
            shareBackgroundView.align(.UnderCentered, relativeTo: textInputView, padding: 0, width: view.frame.width + 2, height: 120)
        } else {
            shareBackgroundView.anchorInCorner(.BottomLeft, xPad: -1, yPad: 126, width: view.frame.width + 2, height: 120)
        }
        
        let socialPadX = (view.frame.width - 2 * 120) / 3
        facebookSocialButton.anchorInCorner(.TopLeft, xPad: socialPadX, yPad: 10, width: 120, height: 23)
        twitterSocialButton.anchorInCorner(.TopRight, xPad: socialPadX, yPad: 10, width: 120, height: 23)
        instagramSocialButton.anchorInCorner(.BottomLeft, xPad: socialPadX, yPad: 30, width: 120, height: 23)
        moreSocialButton.anchorInCorner(.BottomRight, xPad: socialPadX, yPad: 30, width: 120, height: 23)
        
        cameraButton.align(.UnderCentered, relativeTo: shareBackgroundView, padding: 25, width: 80, height: 80)
        //postLater.align(.ToTheRightMatchingBottom, relativeTo: cameraButton, padding: view.frame.width/4, width: postLater.icon.size.width, height: postLater.icon.size.height)
        postLater.anchorInCorner(.BottomRight, xPad: 20, yPad: view.frame.size.height - (cameraButton.frame.size.height + cameraButton.frame.origin.y - 10), width: postLater.icon.size.width, height: postLater.icon.size.height)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SaveThetaViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SaveThetaViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        tabController!.disableScrollView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.fontDisplay(14, withType: .Regular),
            NSForegroundColorAttributeName: UIColor(hex:0xffbc00),
        ]

        
        Mixpanel.sharedInstance().timeEvent("View.CreateOptograph")
        
        // needed if user re-enabled location via Settings.app
        locationView.reloadLocation()
        
        if !SessionService.isLoggedIn {
            //tabController!.hideUI()
            
//            let loginOverlayViewController = LoginOverlayViewController(
//                title: "Login to save your moment",
//                successCallback: {
//                    self.readyNotification.notify(())
//                },
//                cancelCallback: {
//                    self.readyNotification.notify(())
//                    return true
//                },
//                alwaysCallback: {
//                    //self.tabController!.unlockUI()
//                    self.tabController!.showUI()
//                }
//            )
//            presentViewController(loginOverlayViewController, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        
        navigationController?.interactivePopGestureRecognizer?.enabled = true
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        
        tabController?.enableScrollView()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.CreateOptograph")
    }
    
    func updateTabs() {
        
        //tabView.bottomGradientOffset.value = 0
        //tabView.leftButton.hidden = true
        //tabView.rightButton.hidden = true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        if let touch = touches.first {
            let point = touch.locationInView(scnView)
            touchRotationSource.touchStart(CGPoint(x: point.x, y: 0))
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        
        dragTextView.hidden = true
        touchRotationSource.dampFactor = 0.9
        
        if let touch = touches.first {
            let point = touch.locationInView(scnView)
            touchRotationSource.touchMove(CGPoint(x: point.x, y: 0))
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        
        if touches.count == 1 {
            touchRotationSource.touchEnd()
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        
        if touches?.count == 1 {
            touchRotationSource.touchEnd()
        }
    }
    
    dynamic private func keyboardWillShow(notification: NSNotification) {
        scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height)
    }
    
    dynamic private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    dynamic private func cancel() {
        
        let confirmAlert = UIAlertController(title: "Discard Moment?", message: "If you go back now, the recording will be discarded.", preferredStyle: .Alert)
        confirmAlert.addAction(UIAlertAction(title: "Discard", style: .Destructive, handler: { _ in
            PipelineService.stopStitching()
            
//            self.viewModel.optographBox.insertOrUpdate { box in
//                box.model.deletedAt = NSDate()
//            }
//            if StitchingService.hasUnstitchedRecordings() {
//                StitchingService.removeUnstitchedRecordings()
//            }
//            
//            self.navigationController!.popViewControllerAnimated(true)
            
        }))
        confirmAlert.addAction(UIAlertAction(title: "Keep", style: .Cancel, handler: nil))
        navigationController!.presentViewController(confirmAlert, animated: true, completion: nil)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    dynamic private func togglePrivate() {
        let settingsSheet = UIAlertController(title: "Set Visibility", message: "Who should be able to see your moment?", preferredStyle: .ActionSheet)
        
        settingsSheet.addAction(UIAlertAction(title: "Everybody (Default)", style: .Default, handler: { [weak self] _ in
            self?.viewModel.isPrivate.value = false
            }))
        
        settingsSheet.addAction(UIAlertAction(title: "Just me", style: .Destructive, handler: { [weak self] _ in
            self?.viewModel.isPrivate.value = true
            }))
        
        settingsSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        
        navigationController?.presentViewController(settingsSheet, animated: true, completion: nil)
    }
    
    private func signupAlert() {
        let alert = UIAlertController(title: "Login Needed", message: "In order to share your moment you need to create an account. Your image won't be lost and can be shared afterwards.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .Default, handler: { _ in return }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    private func offlineAlert() {
        let alert = UIAlertController(title: "No Network Connection", message: "In order to share your moment you need a network connection. Your image won't be lost and can still be shared later.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .Default, handler: { _ in return }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    dynamic private func tapFacebookSocialButton() {
        if !viewModel.isLoggedIn.value {
            signupAlert()
            return
        }
        
        let loginManager = FBSDKLoginManager()
        let publishPermissions = ["publish_actions"]
        
        let errorBlock = { [weak self] (message: String) in
            self?.viewModel.postFacebook.value = false
            
            let alert = UIAlertController(title: "Facebook Signin unsuccessful", message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Try again", style: .Default, handler: { _ in return }))
            self?.presentViewController(alert, animated: true, completion: nil)
        }
        
        let successBlock = { [weak self] (token: FBSDKAccessToken!) in
            let parameters  = [
                "facebook_user_id": token.userID,
                "facebook_token": token.tokenString,
                ]
            ApiService<EmptyResponse>.put("persons/me", parameters: parameters)
                .on(
                    failed: { _ in
                        errorBlock("Something went wrong and we couldn't sign you in. Please try again.")
                    },
                    completed: { [weak self] in
                        self?.viewModel.postFacebook.value = true
                    }
                )
                .start()
        }
        
        if let token = FBSDKAccessToken.currentAccessToken() where publishPermissions.reduce(true, combine: { $0 && token.hasGranted($1) }) {
            viewModel.postFacebook.value = !viewModel.postFacebook.value
            return
        }
        
        if !viewModel.isOnline.value {
            offlineAlert()
            return
        }
        
        facebookSocialButton.state = .Loading
        
        loginManager.logInWithPublishPermissions(publishPermissions, fromViewController: self) { [weak self] result, error in
            if error != nil || result.isCancelled {
                self?.viewModel.postFacebook.value = false
                loginManager.logOut()
            } else {
                let grantedPermissions = result.grantedPermissions.map( {"\($0)"} )
                let allPermissionsGranted = publishPermissions.reduce(true) { $0 && grantedPermissions.contains($1) }
                
                if allPermissionsGranted {
                    successBlock(result.token)
                } else {
                    errorBlock("Please allow access to all points in the list. Don't worry, your data will be kept safe.")
                }
            }
        }
    }
    
    dynamic private func tapTwitterSocialButton() {
        if !viewModel.isLoggedIn.value {
            signupAlert()
            return
        }
        
        twitterSocialButton.state = .Loading
        
        if let session = Twitter.sharedInstance().sessionStore.session() {
            let newValue = !viewModel.postTwitter.value
            
            if !newValue {
                viewModel.postTwitter.value = newValue
                return
            }
            
            let parameters  = [
                "twitter_token": session.authToken,
                "twitter_secret": session.authTokenSecret,
                ]
            ApiService<EmptyResponse>.put("persons/me", parameters: parameters)
                .on(
                    failed: { [weak self] _ in
                        //                                errorBlock("Something went wrong and we couldn't sign you in. Please try again.")
                        self?.viewModel.postTwitter.value = !newValue
                    },
                    completed: { [weak self] in
                        self?.viewModel.postTwitter.value = newValue
                    }
                )
                .start()
            
        } else {
            if !viewModel.isOnline.value {
                offlineAlert()
                return
            }
            
            Twitter.sharedInstance().logInWithViewController(self) { [weak self] (session, error) in
                if let session = session {
                    let parameters  = [
                        "twitter_token": session.authToken,
                        "twitter_secret": session.authTokenSecret,
                        ]
                    ApiService<EmptyResponse>.put("persons/me", parameters: parameters)
                        .on(
                            failed: { [weak self] _ in
                                //                                errorBlock("Something went wrong and we couldn't sign you in. Please try again.")
                                self?.viewModel.postTwitter.value = false
                            },
                            completed: { [weak self] in
                                self?.viewModel.postTwitter.value = true
                            }
                        )
                        .start()
                } else {
                    self?.viewModel.postTwitter.value = false
                }
            }
        }
    }
    
    dynamic private func tapInstagramSocialButton() {
        if !viewModel.isLoggedIn.value {
            signupAlert()
            return
        }
        
        viewModel.postInstagram.value = !viewModel.postInstagram.value
    }
    
    dynamic private func tapMoreSocialButton() {
        if !viewModel.isLoggedIn.value {
            signupAlert()
            return
        }
        
        moreSocialButton.state = .Loading
        
        let shareAlias = viewModel.optographBox.model.shareAlias
        
        Async.main { [weak self] in
            let textToShare = "Check out this awesome Optograph"
            let baseURL = Env == .Staging ? "staging.opto.space:8005" : "opto.space"
            let url = NSURL(string: "http://\(baseURL)/\(shareAlias)")!
            let activityVC = UIActivityViewController(activityItems: [textToShare, url], applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivityTypeAirDrop]
            
            self?.navigationController?.presentViewController(activityVC, animated: true) { [weak self] _ in
                self?.moreSocialButton.state = .Unselected
            }
        }
    }
    
    private func submit(shouldBePublished: Bool) {
        viewModel.submit(shouldBePublished, directionPhi: Double(touchRotationSource.phi), directionTheta: Double(touchRotationSource.theta))
            .observeOnMain()
            .on(
                started: { [weak self] in
                    self?.cameraButton.loading = true
                    self?.postLater.loading = true
                },
                completed: { [weak self] in
                    Mixpanel.sharedInstance().track("Action.CreateOptograph.Post")
                    self?.navigationController!.popViewControllerAnimated(true)
                    
                    if Defaults[.SessionUploadMode] == "theta" {
                        self?.viewModel.uploadForThetaOk()
                    }
                }
            )
            .start()
    }
}


// MARK: - UITextViewDelegate
extension SaveThetaViewController: UITextViewDelegate {
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            view.endEditing(true)
            return false
        }
        return true
    }
    
}


// MARK: - TabControllerDelegate
extension SaveThetaViewController: TabControllerDelegate {
    
    func onTapCameraButton() {
        if viewModel.isReadyForSubmit.value {
            submit(true)
        }
    }
    
    func onTapLeftButton() {
        let confirmAlert = UIAlertController(title: "Discard Moment?", message: "If you go back now, the current recording will be discarded.", preferredStyle: .Alert)
        confirmAlert.addAction(UIAlertAction(title: "Retry", style: .Destructive, handler: { [weak self] _ in
            if let strongSelf = self {
                let cameraViewController = CameraViewController()
                strongSelf.navigationController!.pushViewController(cameraViewController, animated: false)
                
                strongSelf.navigationController!.viewControllers.removeAtIndex(strongSelf.navigationController!.viewControllers.count - 2)
            }
            }))
        confirmAlert.addAction(UIAlertAction(title: "Keep", style: .Cancel, handler: nil))
        navigationController!.presentViewController(confirmAlert, animated: true, completion: nil)
        
    }
    
    func onTapRightButton() {
        if viewModel.isReadyForSubmit.value {
            submit(false)
        }
    }
    
}

private class ScrollView: UIScrollView {
    
    weak var scnView: SCNView!
    
    private override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        return point.y > scnView.height
    }
}

private class LocationViewModel {
    
    enum State { case Disabled, Selection }
    
    let locations = MutableProperty<[GeocodePreview]>([])
    let selectedLocation = MutableProperty<Int?>(nil)
    let state: MutableProperty<State>
    
    let locationSignal = NotificationSignal<Void>()
    let locationEnabled = MutableProperty<Bool>(false)
    let locationLoading = MutableProperty<Bool>(false)
    
    var locationPermissionTimer: NSTimer?
    
    weak var isOnline: MutableProperty<Bool>!
    
    init(isOnline: MutableProperty<Bool>) {
        self.isOnline = isOnline
        
        locationEnabled.value = LocationService.enabled
        
        state = MutableProperty(LocationService.enabled ? .Selection : .Disabled)
        
        locationSignal.signal
            .map { _ in self.locationEnabled.value }
            .filter(identity)
            .flatMap(.Latest) { [weak self] _ in
                LocationService.location()
                    .take(1)
                    .on(next: { (lat, lon) in
                        self?.locationLoading.value = true
                        self?.selectedLocation.value = nil
                        var location = Location.newInstance()
                        location.latitude = lat
                        location.longitude = lon
                    })
                    .ignoreError()
            }
            .flatMap(.Latest) { (lat, lon) -> SignalProducer<[GeocodePreview], NoError> in
                if isOnline.value {
                    return ApiService<GeocodePreview>.get("locations/geocode-reverse", queries: ["lat": "\(lat)", "lon": "\(lon)"])
                        .on(failed: { [weak self] _ in
                            self?.isOnline.value = false
                            self?.locationLoading.value = false
                            })
                        .failedAsNext { _ in GeocodePreview(name: "Use location (\(lat.roundToPlaces(1)), \(lon.roundToPlaces(1)))") }
                        .collect()
                } else {
                    return SignalProducer(value: [GeocodePreview(name: "Use location (\(lat.roundToPlaces(1)), \(lon.roundToPlaces(1)))")])
                }
            }
            .observeNext { [weak self] locations in
                self?.locationLoading.value = false
                self?.locations.value = locations
        }
        
    }
    
    deinit {
        locationPermissionTimer?.invalidate()
    }
    
    func enableLocation() {
        locationPermissionTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(LocationViewModel.checkLocationPermission), userInfo: nil, repeats: true)
        LocationService.askPermission()
    }
    
    dynamic private func checkLocationPermission() {
        let enabled = LocationService.enabled
        state.value = enabled ? .Selection : .Disabled
        if locationPermissionTimer != nil && enabled {
            locationEnabled.value = true
            locationSignal.notify(())
            locationPermissionTimer?.invalidate()
            locationPermissionTimer = nil
        }
    }
}

private struct GeocodePreview: Mappable {
    var placeID = ""
    var name = ""
    var vicinity = ""
    
    init(name: String) {
        self.name = name
    }
    
    init() {}
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        placeID  <- map["place_id"]
        name     <- map["name"]
        vicinity <- map["vicinity"]
    }
}

private class LocationCollectionViewCell: UICollectionViewCell {
    
    private let textView = UILabel()
    
    var text = "" {
        didSet {
            textView.text = text
        }
    }
    
    var isSelected = false {
        didSet {
            contentView.backgroundColor = isSelected ? UIColor(0x5f5f5f) : UIColor(0xefefef)
            textView.textColor = isSelected ? .whiteColor() : UIColor(0x5f5f5f)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 4
        
        textView.font = UIFont.displayOfSize(11, withType: .Semibold)
        textView.textColor = UIColor(0x5f5f5f)
        contentView.addSubview(textView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func layoutSubviews() {
        super.layoutSubviews()
        
        textView.fillSuperview(left: 10, right: 10, top: 0, bottom: 0)
    }
    
}

private class LocationView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let bottomBorder = CALayer()
    private let leftIconView = UIImageView()
    private let statusText = UILabel()
    private let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    var didSelectLocation: (String? -> ())?
    
    var viewModel: LocationViewModel!
    
    private var locations: [GeocodePreview] = []
    
    convenience init(isOnline: MutableProperty<Bool>) {
        self.init(frame: CGRectZero)
        
        viewModel = LocationViewModel(isOnline: isOnline)
        
        bottomBorder.backgroundColor = UIColor(0xe6e6e6).CGColor
        layer.addSublayer(bottomBorder)
        
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = .Horizontal
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.registerClass(LocationCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = .clearColor()
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsSelection = true
        collectionView.rac_hidden <~ viewModel.locationLoading
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 16)
        viewModel.locations.producer.startWithNext { [weak self] locations in
            self?.locations = locations
            self?.collectionView.reloadData()
        }
        viewModel.selectedLocation.producer.startWithNext { [weak self] _ in self?.collectionView.reloadData() }
        addSubview(collectionView)
        
        loadingIndicator.rac_animating <~ viewModel.locationLoading
        loadingIndicator.hidesWhenStopped = true
        addSubview(loadingIndicator)
        
//        leftIconView.font = UIFont.iconOfSize(24)
//        leftIconView.textColor = UIColor(0x919293)
        leftIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LocationView.didTap)))
        leftIconView.userInteractionEnabled = true
        leftIconView.image = UIImage(named:"location_pin")
        //leftIconView.text = String.iconWithName(.Location)
        addSubview(leftIconView)
        
        statusText.font = UIFont.displayOfSize(13, withType: .Semibold)
        statusText.textColor = UIColor(0x919293)
        statusText.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LocationView.didTap)))
        statusText.userInteractionEnabled = true
        statusText.rac_hidden <~ viewModel.locationEnabled
        statusText.text = "Add location"
        addSubview(statusText)
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        bottomBorder.frame = CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1)
        leftIconView.frame = CGRect(x: 16, y: 22, width: leftIconView.image!.size.width, height: leftIconView.image!.size.height)
        statusText.frame = CGRect(x: 54, y: 22, width: 200, height: 24)
        loadingIndicator.frame = CGRect(x: 54, y: 20, width: 28, height: 28)
        collectionView.frame = CGRect(x: 54, y: 0, width: frame.width - 54, height: 68)
    }
    
    dynamic private func didTap() {
        if viewModel.locationEnabled.value {
            reloadLocation()
        } else {
            enableLocation()
        }
    }
    
    dynamic private func enableLocation() {
        viewModel.enableLocation()
    }
    
    dynamic func reloadLocation() {
        didSelectLocation?(nil)
        viewModel.locationSignal.notify(())
    }
    
    dynamic private func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! LocationCollectionViewCell
        let location = locations[indexPath.row]
        cell.text = "\(location.name)"
        cell.isSelected = viewModel.selectedLocation.value == indexPath.row
        return cell
    }
    
    dynamic func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    dynamic func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locations.count
    }
    
    dynamic private func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let location = locations[indexPath.row]
        let text = "\(location.name)"
        return CGSize(width: calcTextWidth(text, withFont: .displayOfSize(11, withType: .Semibold)) + 20, height: 28)
    }
    
    dynamic private func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if viewModel.selectedLocation.value == indexPath.row {
            viewModel.selectedLocation.value = nil
            didSelectLocation?(nil)
        } else {
            viewModel.selectedLocation.value = indexPath.row
            didSelectLocation?(locations[indexPath.row].placeID)
        }
    }
    
}

private class SocialButton: UIView {
    
    private let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    private let textView = UILabel()
    private var touched = false
    private var iconView2 = UIImageView()
    
    var text = "" {
        didSet {
            textView.text = text
        }
    }
    
    var icon2:UIImage = UIImage(named:"facebook_save_active")! {
        didSet {
            iconView2.image = icon2
        }
    }
    
    var color = UIColor.Accent {
        didSet {
            updateColors()
        }
    }
    
    enum State { case Selected, Unselected, Loading }
    
    var state: State = .Unselected {
        didSet {
            updateColors()
        }
    }
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        textView.font = UIFont.displayOfSize(16, withType: .Semibold)
        addSubview(textView)

        addSubview(iconView2)
        
        updateColors()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        let iconHeight = UIImage(named:"facebook_save_active")!.size.height
        let iconWidth = UIImage(named:"facebook_save_active")!.size.width
        
        loadingView.frame = CGRect(x: 0, y: 0, width: iconHeight, height: iconHeight)
        textView.frame = CGRect(x: 45, y: 10, width: 77, height: 17)
    
        
        iconView2.frame = CGRect(x: 0,y: 0,width: iconWidth,height: iconHeight)
        
    }
    
    private override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        touched = true
        updateColors()
    }
    
    private override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        touched = false
        updateColors()
    }
    
    private override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        touched = false
        updateColors()
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let margin: CGFloat = 5
        let area = CGRectInset(bounds, -margin, -margin)
        return CGRectContainsPoint(area, point)
    }
    
    private func updateColors() {
        if state == .Loading {
            loadingView.startAnimating()
            iconView2.hidden = true
        } else {
            loadingView.stopAnimating()
            iconView2.hidden = false
        }
        
        var textColor = UIColor(0x919293)
        if touched {
            textColor = color.alpha(0.7)
        } else if state == .Selected {
            textColor = color
        }
        
        textView.textColor = textColor
    }
}
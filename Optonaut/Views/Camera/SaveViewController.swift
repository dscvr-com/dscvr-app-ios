//
//  EditProfileViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import KMPlaceholderTextView
import Mixpanel
import ActiveLabel
import Async
import AVFoundation
import SceneKit
import ObjectMapper
import FBSDKLoginKit
import TwitterKit

class SaveViewController: UIViewController, RedNavbar {
    
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
    private let locationView = LocationView()
    private let textInputView = UITextView()
    private let textPlaceholderView = UILabel()
    private let shareBackgroundView = UIView()
    private let facebookSocialButton = SocialButton()
    private let twitterSocialButton = SocialButton()
    private let instagramSocialButton = SocialButton()
    private let moreSocialButton = SocialButton()
    private var placeholderImage: UIImage?
    
    required init(recorderCleanup: SignalProducer<UIImage, NoError>) {
        
        let (placeholderSignal, placeholderSink) = Signal<UIImage, NoError>.pipe()
        
        viewModel = SaveViewModel(placeholderSignal: placeholderSignal)
        
        super.init(nibName: nil, bundle: nil)
        
        recorderCleanup
            .startOn(QueueScheduler(queue: dispatch_queue_create("recorderQueue", DISPATCH_QUEUE_SERIAL)))
            .on(event: { event in
                placeholderSink.action(event)
            })
            .observeOnMain()
            .on(next: { [weak self] image in
                if let renderDelegate = self?.renderDelegate {
                    renderDelegate.image = image
                } else {
                    self?.placeholderImage = image
                }
            })
            .start()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SAVE THE MOMENT"
        
        let cancelButton = UILabel(frame: CGRect(x: 0, y: -2, width: 24, height: 24))
        cancelButton.text = String.iconWithName(.Cancel)
        cancelButton.textColor = .whiteColor()
        cancelButton.font = UIFont.iconOfSize(18)
        cancelButton.userInteractionEnabled = true
        cancelButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        let privateButton = UILabel(frame: CGRect(x: 0, y: -2, width: 24, height: 24))
        privateButton.textColor = .whiteColor()
        privateButton.font = UIFont.iconOfSize(18)
        privateButton.rac_text <~ viewModel.isPrivate.producer.mapToTuple(.iconWithName(.Safe), .iconWithName(.Safe))
        privateButton.userInteractionEnabled = true
        privateButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "togglePrivate"))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: privateButton)
        
        view.backgroundColor = .whiteColor()
        
        scnView = SCNView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 0.46 * view.frame.width))
        
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
        
        renderDelegate.image = placeholderImage
        
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
        shareBackgroundView.rac_userInteractionEnabled <~ viewModel.isOnline
        shareBackgroundView.rac_alpha <~ viewModel.isOnline.producer.mapToTuple(1, 0.5)
        scrollView.addSubview(shareBackgroundView)
        
        facebookSocialButton.icon = String.iconWithName(.Facebook)
        facebookSocialButton.text = "Facebook"
        facebookSocialButton.color = UIColor(0x3b5998)
        facebookSocialButton.userInteractionEnabled = true
        facebookSocialButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapFacebookSocialButton"))
        shareBackgroundView.addSubview(facebookSocialButton)
        
        viewModel.postFacebook.producer.startWithNext { [weak self] toggled in
            self?.facebookSocialButton.state = toggled ? .Selected : .Unselected
        }
        
        twitterSocialButton.icon = String.iconWithName(.Twitter)
        twitterSocialButton.text = "Twitter"
        twitterSocialButton.color = UIColor(0x55acee)
        twitterSocialButton.userInteractionEnabled = true
        twitterSocialButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapTwitterSocialButton"))
        shareBackgroundView.addSubview(twitterSocialButton)
        
        viewModel.postTwitter.producer.startWithNext { [weak self] toggled in
            self?.twitterSocialButton.state = toggled ? .Selected : .Unselected
        }
        
        instagramSocialButton.icon = String.iconWithName(.Instagram)
        instagramSocialButton.text = "Instagram"
        instagramSocialButton.color = UIColor(0x9b6954)
        instagramSocialButton.userInteractionEnabled = true
        instagramSocialButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapInstagramSocialButton"))
        shareBackgroundView.addSubview(instagramSocialButton)
        
        viewModel.postInstagram.producer.startWithNext { [weak self] toggled in
            self?.instagramSocialButton.state = toggled ? .Selected : .Unselected
        }
        
        moreSocialButton.icon = String.iconWithName(.ShareAlt)
        moreSocialButton.text = "More"
        moreSocialButton.rac_userInteractionEnabled <~ viewModel.isReady
        moreSocialButton.rac_alpha <~ viewModel.isReady.producer.mapToTuple(1, 0.5)
        moreSocialButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapMoreSocialButton"))
        shareBackgroundView.addSubview(moreSocialButton)
        
        scrollView.scnView = scnView
        view.addSubview(scrollView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
        
        updateTabs()
        
        viewModel.isReady.producer.startWithNext { [weak self] isReady in
            self?.tabController!.cameraButton.loading = !isReady
            self?.tabController!.rightButton.loading = !isReady
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let contentHeight = 0.46 * view.frame.width + 120 + 68 + 105 + 126
        let scrollEnabled = contentHeight > view.frame.height
        scrollView.contentSize = CGSize(width: view.frame.width, height: scrollEnabled ? contentHeight : view.frame.height)
        scrollView.scrollEnabled = scrollEnabled
        
        scrollView.fillSuperview()
        locationView.alignAndFillWidth(align: .UnderCentered, relativeTo: scnView, padding: 0, height: 68)
        textInputView.alignAndFillWidth(align: .UnderCentered, relativeTo: locationView, padding: 0, height: 120)
        textPlaceholderView.anchorInCorner(.TopLeft, xPad: 16, yPad: 7, width: 250, height: 20)
        
        if scrollEnabled {
            shareBackgroundView.align(.UnderCentered, relativeTo: textInputView, padding: 0, width: view.frame.width + 2, height: 105)
        } else {
            shareBackgroundView.anchorInCorner(.BottomLeft, xPad: -1, yPad: 126, width: view.frame.width + 2, height: 105)
        }
        
        let socialPadX = (view.frame.width - 2 * 120) / 3
        facebookSocialButton.anchorInCorner(.TopLeft, xPad: socialPadX, yPad: 20, width: 120, height: 23)
        twitterSocialButton.anchorInCorner(.TopRight, xPad: socialPadX, yPad: 20, width: 120, height: 23)
        instagramSocialButton.anchorInCorner(.BottomLeft, xPad: socialPadX, yPad: 20, width: 120, height: 23)
        moreSocialButton.anchorInCorner(.BottomRight, xPad: socialPadX, yPad: 20, width: 120, height: 23)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.displayOfSize(14, withType: .Regular),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        
        tabController!.delegate = self
        
        Mixpanel.sharedInstance().timeEvent("View.CreateOptograph")
        
        // needed if user re-enabled location via Settings.app
        locationView.reloadLocation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        
        navigationController?.interactivePopGestureRecognizer?.enabled = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.CreateOptograph")
    }
    
    override func updateTabs() {
        tabController!.leftButton.title = "RETRY"
        tabController!.leftButton.icon = .Camera
        tabController!.leftButton.hidden = false
        tabController!.leftButton.color = .Light
        tabController!.leftButton.isActive = true
        
        tabController!.rightButton.title = "POST LATER"
        tabController!.rightButton.icon = .Clock
        tabController!.rightButton.hidden = false
        tabController!.rightButton.color = .Light
        tabController!.rightButton.isActive = true
        
        tabController!.cameraButton.setTitle(String.iconWithName(.Next), forState: .Normal)
        tabController!.cameraButton.setTitleColor(UIColor.whiteColor().alpha(0), forState: .Normal)
        tabController!.cameraButton.backgroundColor = .Accent
        
        tabController!.bottomGradientOffset.value = 0
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
    
    @objc
    private func keyboardWillShow(notification: NSNotification) {
        scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height)
    }
    
    @objc
    private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    @objc
    private func cancel() {
        let confirmAlert = UIAlertController(title: "Discard Moment?", message: "If you go back now, the recording will be discarded.", preferredStyle: .Alert)
        confirmAlert.addAction(UIAlertAction(title: "Discard", style: .Destructive, handler: { [weak self] _ in
            self?.navigationController!.popViewControllerAnimated(false)
        }))
        confirmAlert.addAction(UIAlertAction(title: "Keep", style: .Cancel, handler: nil))
        navigationController!.presentViewController(confirmAlert, animated: true, completion: nil)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc
    private func togglePrivate() {
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
    
    @objc private func tapFacebookSocialButton() {
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
    
    @objc private func tapTwitterSocialButton() {
//        print(Twitter.sharedInstance().sessionStore.session()!.userID)
        if let session = Twitter.sharedInstance().sessionStore.session() {
            print(session.userID)
        }
        if Twitter.sharedInstance().sessionStore.session() == nil {
            twitterSocialButton.state = .Loading
            
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
        } else {
            viewModel.postTwitter.value = !viewModel.postTwitter.value
        }
    }
    
    @objc private func tapInstagramSocialButton() {
        viewModel.postInstagram.value = !viewModel.postInstagram.value
    }
    
    @objc private func tapMoreSocialButton() {
        moreSocialButton.state = .Loading
        
        Async.main { [weak self] in
            let textToShare = "Check out this awesome Optograph"
            let url = NSURL(string: "http://opto.space/uae")!
            let activityVC = UIActivityViewController(activityItems: [textToShare, url], applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivityTypeAirDrop]
            
            self?.navigationController?.presentViewController(activityVC, animated: true) { [weak self] _ in
                self?.moreSocialButton.state = .Unselected
            }
        }
    }
    
    private func submit(shouldBePublished: Bool) {
        viewModel.optograph.directionPhi = Double(touchRotationSource.phi)
        viewModel.optograph.directionTheta = Double(touchRotationSource.theta)
        
        viewModel.submit(shouldBePublished)
            .observeOnMain()
            .on(
                started: { [weak self] in
                    self?.tabController!.cameraButton.loading = true
                    self?.tabController!.rightButton.loading = true
                },
                completed: { [weak self] in
                    Mixpanel.sharedInstance().track("Action.CreateOptograph.Post")
                    self?.tabController!.cameraButton.loading = false
                    self?.tabController!.rightButton.loading = false
                    PipelineService.check()
                    self?.navigationController?.popViewControllerAnimated(false)
                }
            )
            .start()
    }
    
}


// MARK: - UITextViewDelegate
extension SaveViewController: UITextViewDelegate {

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            view.endEditing(true)
            return false
        }
        return true
    }
    
}


// MARK: - TabControllerDelegate
extension SaveViewController: TabControllerDelegate {
    
    func onTapCameraButton() {
        submit(true)
    }
    
    func onTapLeftButton() {
        let confirmAlert = UIAlertController(title: "Discard Moment?", message: "If you go back now, the current recording will be discarded.", preferredStyle: .Alert)
        confirmAlert.addAction(UIAlertAction(title: "Retry", style: .Destructive, handler: { [weak self] _ in
            if let strongSelf = self {
                strongSelf.navigationController!.pushViewController(CameraViewController(), animated: false)
                strongSelf.navigationController!.viewControllers.removeAtIndex(strongSelf.navigationController!.viewControllers.count - 2)
            }
        }))
        confirmAlert.addAction(UIAlertAction(title: "Keep", style: .Cancel, handler: nil))
        navigationController!.presentViewController(confirmAlert, animated: true, completion: nil)
        
    }
    
    func onTapRightButton() {
        submit(false)
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
    
    init() {
        
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
                if Reachability.connectedToNetwork() {
                    return ApiService<GeocodePreview>.get("locations/geocode-reverse", queries: ["lat": "\(lat)", "lon": "\(lon)"])
                        .on(failed: { _ in
                            self.locationLoading.value = false
                        })
                        .ignoreError()
                        .collect()
                } else {
                    var fallbackLocation = GeocodePreview()
                    fallbackLocation.name = "Use location (\(lat.roundToPlaces(1)), \(lon.roundToPlaces(1)))"
                    return SignalProducer(value: [fallbackLocation])
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
        locationPermissionTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("checkLocationPermission"), userInfo: nil, repeats: true)
        LocationService.askPermission()
    }
    
    @objc
    private func checkLocationPermission() {
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
    private let leftIconView = UILabel()
    private let statusText = UILabel()
    private let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    
    var didSelectLocation: (String? -> ())?
    
    private let viewModel = LocationViewModel()
    
    private var locations: [GeocodePreview] = []
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        bottomBorder.backgroundColor = UIColor(0x9d9d9d).CGColor
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
        
        leftIconView.font = UIFont.iconOfSize(24)
        leftIconView.textColor = UIColor(0x919293)
        leftIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "didTap"))
        leftIconView.userInteractionEnabled = true
        leftIconView.text = String.iconWithName(.Location)
        addSubview(leftIconView)
        
        statusText.font = UIFont.displayOfSize(13, withType: .Semibold)
        statusText.textColor = UIColor(0x919293)
        statusText.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "didTap"))
        statusText.userInteractionEnabled = true
        statusText.rac_hidden <~ viewModel.locationEnabled
        statusText.text = "Add location"
        addSubview(statusText)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bottomBorder.frame = CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1)
        leftIconView.frame = CGRect(x: 16, y: 22, width: 24, height: 24)
        statusText.frame = CGRect(x: 54, y: 22, width: 200, height: 24)
        loadingIndicator.frame = CGRect(x: 54, y: 20, width: 28, height: 28)
        collectionView.frame = CGRect(x: 54, y: 0, width: frame.width - 54, height: 68)
    }
    
    @objc private func didTap() {
        if viewModel.locationEnabled.value {
            reloadLocation()
        } else {
            enableLocation()
        }
    }
    
    @objc private func enableLocation() {
        viewModel.enableLocation()
    }
    
    @objc func reloadLocation() {
        didSelectLocation?(nil)
        viewModel.locationSignal.notify(())
    }
    
    @objc private func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! LocationCollectionViewCell
        let location = locations[indexPath.row]
        cell.text = "\(location.name)"
        cell.isSelected = viewModel.selectedLocation.value == indexPath.row
        return cell
    }

    @objc func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    @objc func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locations.count
    }
    
    @objc private func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let location = locations[indexPath.row]
        let text = "\(location.name)"
        return CGSize(width: calcTextWidth(text, withFont: .displayOfSize(11, withType: .Semibold)) + 20, height: 28)
    }
    
    @objc private func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
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
    
    private let iconView = UILabel()
    private let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    private let textView = UILabel()
    private var touched = false
    
    var text = "" {
        didSet {
            textView.text = text
        }
    }
    
    var icon = "" {
        didSet {
            iconView.text = icon
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
        
        iconView.font = UIFont.iconOfSize(23)
        addSubview(iconView)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        textView.font = UIFont.displayOfSize(16, withType: .Semibold)
        addSubview(textView)
        
        updateColors()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
        loadingView.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
        textView.frame = CGRect(x: 34, y: 3, width: 77, height: 17)
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
            iconView.hidden = true
        } else {
            loadingView.stopAnimating()
            iconView.hidden = false
        }
        
        var textColor = UIColor(0x919293)
        if touched {
            textColor = color.alpha(0.7)
        } else if state == .Selected {
            textColor = color
        }
        
        textView.textColor = textColor
        iconView.textColor = textColor
    }
}
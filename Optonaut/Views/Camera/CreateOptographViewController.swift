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
import AVFoundation

class CreateOptographViewController: UIViewController, TransparentNavbar {
    
    private let viewModel = CreateOptographViewModel()
    
    // camera
    private let session = AVCaptureSession()
    private let sessionQueue: dispatch_queue_t
    private let stillImageOutput = AVCaptureStillImageOutput()
    
    // subviews
    private let previewImageView = PlaceholderImageView()
    private let cameraPreviewImageView = UIView()
    private let cameraPreviewImageBlurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    private let enableCameraButtonView = HatchedButton()
    private let enableCameraTextView = UILabel()
    private let cameraButtonView = HatchedButton()
    private let submitButtonView = HatchedButton()
    private let locationIconView = UILabel()
    private let locationView = UILabel()
    private let locationWarningView = UILabel()
    private let locationEnableView = UILabel()
    private let locationReloadView = UILabel()
    private let descriptionView = ActiveLabel()
    private let textInputView = KMPlaceholderTextView()
    private let hashtagInputView = RoundedTextField()
    private let backgroundView = BackgroundView()
    
    required init() {
        let high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        sessionQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
        dispatch_set_target_queue(sessionQueue, high)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
        previewImageView.placeholderImage = UIImage(named: "optograph-placeholder")!
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.rac_url <~ viewModel.previewImageUrl
        previewImageView.rac_hidden <~ viewModel.cameraPreviewEnabled
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "enableCamera"))
        view.addSubview(previewImageView)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        cameraPreviewImageView.backgroundColor = .DarkGrey
        cameraPreviewImageView.layer.addSublayer(previewLayer)
        cameraPreviewImageView.rac_hidden <~ viewModel.cameraPreviewEnabled.producer.map(negate)
        view.addSubview(cameraPreviewImageView)
        
        cameraPreviewImageBlurView.rac_hidden <~ viewModel.cameraPreviewBlurred.producer.map(negate)
        cameraPreviewImageView.addSubview(cameraPreviewImageBlurView)
        
        enableCameraButtonView.setTitle(String.iconWithName(.CameraAdd), forState: .Normal)
        enableCameraButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        enableCameraButtonView.titleLabel?.font = UIFont.iconOfSize(35)
        enableCameraButtonView.defaultBackgroundColor = UIColor.whiteColor().alpha(0.3)
        enableCameraButtonView.layer.cornerRadius = 52
        enableCameraButtonView.layer.borderColor = UIColor.whiteColor().CGColor
        enableCameraButtonView.layer.borderWidth = 1.5
        enableCameraButtonView.rac_hidden <~ viewModel.cameraPreviewBlurred.producer.map(negate)
        enableCameraButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "enableCamera"))
        view.addSubview(enableCameraButtonView)
        
        enableCameraTextView.text = "Please take a preview picture"
        enableCameraTextView.font = UIFont.displayOfSize(14, withType: .Regular)
        enableCameraTextView.textColor = .whiteColor()
        enableCameraTextView.rac_hidden <~ viewModel.cameraPreviewBlurred.producer.map(negate)
        view.addSubview(enableCameraTextView)
        
        cameraButtonView.rac_hidden <~ viewModel.cameraPreviewBlurred.producer.map(negate)
            .combineLatestWith(viewModel.cameraPreviewEnabled.producer).map(and)
            .map(negate)
        cameraButtonView.setTitle(String.iconWithName(.Camera), forState: .Normal)
        cameraButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        cameraButtonView.defaultBackgroundColor = .Accent
        cameraButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        cameraButtonView.layer.cornerRadius = 30
        cameraButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "takePicture"))
        view.addSubview(cameraButtonView)
        
        submitButtonView.rac_hidden <~ viewModel.cameraPreviewBlurred.producer.map(negate)
            .combineLatestWith(viewModel.cameraPreviewEnabled.producer).map(or)
        submitButtonView.rac_alpha <~ viewModel.readyToSubmit.producer.map { $0 ? 1 : 0.5 }
        submitButtonView.setTitle(String.iconWithName(.Check), forState: .Normal)
        submitButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        submitButtonView.defaultBackgroundColor = .Accent
        submitButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        submitButtonView.layer.cornerRadius = 30
        submitButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "submit"))
        view.addSubview(submitButtonView)
        
        locationIconView.text = String.iconWithName(.Location)
        locationIconView.font = UIFont.iconOfSize(15)
        locationIconView.rac_textColor <~ viewModel.locationEnabled.producer.map { $0 ? .DarkGrey : .Accent }
        view.addSubview(locationIconView)
        
        locationWarningView.text = "Location required"
        locationWarningView.textColor = .Accent
        locationWarningView.font = UIFont.displayOfSize(16.5, withType: .Thin)
        locationWarningView.rac_hidden <~ viewModel.locationEnabled
        view.addSubview(locationWarningView)
        
        locationEnableView.text = "enable now"
        locationEnableView.textColor =  .Accent
        locationEnableView.font = UIFont.displayOfSize(16.5, withType: .Semibold)
        locationEnableView.rac_hidden <~ viewModel.locationEnabled
        locationEnableView.userInteractionEnabled = true
        locationEnableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "enableLocation"))
        view.addSubview(locationEnableView)
        
        locationView.rac_text <~ viewModel.location
        locationView.rac_hidden <~ viewModel.locationEnabled.producer.map(negate)
        locationView.font = UIFont.displayOfSize(16.5, withType: .Semibold)
        locationView.textColor = .DarkGrey
        view.addSubview(locationView)
        
        locationReloadView.text = String.iconWithName(.Redo)
        locationReloadView.textColor = .DarkGrey
        locationReloadView.font = UIFont.iconOfSize(14)
        locationReloadView.userInteractionEnabled = true
        locationReloadView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "reloadLocation"))
        locationReloadView.rac_hidden <~ viewModel.locationEnabled.producer.map(negate)
        view.addSubview(locationReloadView)
        
        hashtagInputView.size = .Medium
        hashtagInputView.color = .Dark
        hashtagInputView.rac_status <~ viewModel.hashtagStringStatus
        hashtagInputView.placeholder = "Hashtags"
        hashtagInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.hashtagString.value = $0 as! String }
        hashtagInputView.keyboardType = .Twitter
        hashtagInputView.autocorrectionType = .No
        view.addSubview(hashtagInputView)
        
        textInputView.font = UIFont.textOfSize(14, withType: .Regular)
        textInputView.placeholder = "Tell something about what you see..."
        textInputView.placeholderColor = UIColor(0xcfcfcf)
        textInputView.textColor = UIColor(0x4d4d4d)
        textInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.text.value = $0 as! String }
        textInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        textInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        view.addSubview(textInputView)
        
        view.addSubview(backgroundView)
        
        setupCamera()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        cameraPreviewImageView.layer.sublayers?.first?.frame = cameraPreviewImageView.frame
    }
    
    override func updateViewConstraints() {
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: view, withMultiplier: 3 / 4)
        
        cameraPreviewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view)
        cameraPreviewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
        cameraPreviewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: view, withMultiplier: 3 / 4)
        
        cameraPreviewImageBlurView.autoPinEdgesToSuperviewEdges()
        
        enableCameraButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: previewImageView)
        enableCameraButtonView.autoAlignAxis(.Horizontal, toSameAxisOfView: previewImageView, withOffset: -10)
        enableCameraButtonView.autoSetDimension(.Height, toSize: 104)
        enableCameraButtonView.autoSetDimension(.Width, toSize: 104)
        
        enableCameraTextView.autoAlignAxis(.Vertical, toSameAxisOfView: previewImageView)
        enableCameraTextView.autoPinEdge(.Top, toEdge: .Bottom, ofView: enableCameraButtonView, withOffset: 20)
        
        cameraButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView, withOffset: -20)
        cameraButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: previewImageView, withOffset: -20)
        cameraButtonView.autoSetDimension(.Width, toSize: 60)
        cameraButtonView.autoSetDimension(.Height, toSize: 60)
        
        submitButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView, withOffset: -20)
        submitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: previewImageView, withOffset: -20)
        submitButtonView.autoSetDimension(.Width, toSize: 60)
        submitButtonView.autoSetDimension(.Height, toSize: 60)
        
        locationIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 20)
        locationIconView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
        locationIconView.autoSetDimension(.Width, toSize: 15)
        locationIconView.autoSetDimension(.Height, toSize: 15)
        
        locationWarningView.autoPinEdge(.Top, toEdge: .Top, ofView: locationIconView, withOffset: -2)
        locationWarningView.autoPinEdge(.Left, toEdge: .Right, ofView: locationIconView, withOffset: 6)
        
        locationEnableView.autoPinEdge(.Top, toEdge: .Top, ofView: locationWarningView)
        locationEnableView.autoPinEdge(.Left, toEdge: .Right, ofView: locationWarningView, withOffset: 5)
        
        locationView.autoPinEdge(.Top, toEdge: .Top, ofView: locationWarningView)
        locationView.autoPinEdge(.Left, toEdge: .Left, ofView: locationWarningView)
        
        locationReloadView.autoPinEdge(.Top, toEdge: .Top, ofView: locationView, withOffset: 3)
        locationReloadView.autoPinEdge(.Left, toEdge: .Right, ofView: locationView, withOffset: 13)
        
        hashtagInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: locationIconView, withOffset: 25)
        hashtagInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        hashtagInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        
        textInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: hashtagInputView, withOffset: 30)
        textInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        textInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        textInputView.autoSetDimension(.Height, toSize: 100)
        
        backgroundView.autoPinEdge(.Top, toEdge: .Bottom, ofView: textInputView, withOffset: 10)
        backgroundView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view)
        backgroundView.autoPinEdge(.Left, toEdge: .Left, ofView: view)
        backgroundView.autoPinEdge(.Right, toEdge: .Right, ofView: view)
        
        super.updateViewConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        updateNavbarAppear()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.CreateOptograph")
        Mixpanel.sharedInstance().timeEvent("Action.CreateOptograph.Cancel")
        
        // needed if user re-enabled location via Settings.app
        reloadLocation()
        
        session.startRunning()
        
        navigationController?.interactivePopGestureRecognizer?.enabled = false
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
        
        // TODO find better way to do this
        viewModel.locationPermissionTimer?.invalidate()
        
        session.stopRunning()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        view.frame.origin.y = -keyboardHeight + 120
    }
    
    func keyboardWillHide(notification: NSNotification) {
        view.frame.origin.y = 0
    }
    
    private func setupCamera() {
        session.sessionPreset = AVCaptureSessionPresetHigh
        
        let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        session.beginConfiguration()
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        }
        
        let videoDeviceOutput = AVCaptureVideoDataOutput()
        videoDeviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
        videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(videoDeviceOutput) {
            session.addOutput(videoDeviceOutput)
        }
        
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
        
        session.commitConfiguration()
    }
    
    func cancel() {
        Mixpanel.sharedInstance().track("Action.CreateOptograph.Cancel")
        
        StitchingService.cancelStitching()
        navigationController?.popViewControllerAnimated(false)
    }
    
    func submit() {
        if viewModel.previewImageUrl.value.isEmpty {
            return
        }
        
        viewModel.post().startWithNext { optograph in
            self.navigationController?.pushViewController(DetailsTableViewController(optographId: optograph.id), animated: false)
            self.navigationController?.viewControllers.removeAtIndex(1)
        }
    }
    
    func enableCamera() {
        viewModel.cameraPreviewBlurred.value = false
        viewModel.cameraPreviewEnabled.value = true
    }
    
    func enableLocation() {
        viewModel.enableLocation()
    }
    
    func reloadLocation() {
        viewModel.locationSignal.notify()
    }
    
    func takePicture() {
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                let previewImage = OptographAsset.PreviewImage(imageData)
                self.viewModel.optograph.saveAsset(previewImage)
                self.viewModel.saveAsset(imageData)
            }
        }
        viewModel.cameraPreviewEnabled.value = false
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}
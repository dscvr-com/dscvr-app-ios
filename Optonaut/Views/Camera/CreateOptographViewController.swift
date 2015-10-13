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

class CreateOptographViewController: UIViewController {
    
    private let viewModel = CreateOptographViewModel()
    
    // camera
    private let session = AVCaptureSession()
    private let sessionQueue: dispatch_queue_t
    
    // subviews
    private let previewImageView = PlaceholderImageView()
    private let cameraPreviewImageView = UIView()
    private let cameraPreviewImageBlurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    private let cancelButtonView = UIButton()
    private let enableCameraButtonView = ActionButton()
    private let enableCameraTextView = UILabel()
    private let submitButtonView = ActionButton()
    private let infoWrapperView = UIView()
    private let locationIconView = UILabel()
    private let locationTextView = UILabel()
    private let locationCountryView = UILabel()
    private let locationWarningView = UILabel()
    private let locationEnableView = UILabel()
    private let locationReloadView = UILabel()
    private let locationActivityView = UIActivityIndicatorView()
    private let descriptionView = ActiveLabel()
    private let textInputView = KMPlaceholderTextView()
    private let hashtagInputView = LineTextField()
    private let backgroundView = BackgroundView()
    
    private let imagePickerController = UIImagePickerController()
    
    required init() {
        let high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        sessionQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
        dispatch_set_target_queue(sessionQueue, high)
        
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
        
        view.backgroundColor = .whiteColor()
        
        previewImageView.placeholderImage = UIImage(named: "optograph-placeholder")!
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.rac_url <~ viewModel.previewImageUrl
        previewImageView.rac_hidden <~ viewModel.cameraPreviewEnabled
        view.addSubview(previewImageView)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        cameraPreviewImageView.backgroundColor = .DarkGrey
        cameraPreviewImageView.layer.addSublayer(previewLayer)
        cameraPreviewImageView.rac_hidden <~ viewModel.cameraPreviewEnabled.producer.map(negate)
        view.addSubview(cameraPreviewImageView)
        
        cameraPreviewImageView.rac_hidden <~ viewModel.cameraPreviewEnabled.producer.map(negate)
        cameraPreviewImageView.addSubview(cameraPreviewImageBlurView)
        
        cancelButtonView.setTitle(String.iconWithName(.Cross), forState: .Normal)
        cancelButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        cancelButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        cancelButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        view.addSubview(cancelButtonView)
        
        enableCameraButtonView.setTitle(String.iconWithName(.CameraAdd), forState: .Normal)
        enableCameraButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        enableCameraButtonView.titleLabel?.font = UIFont.iconOfSize(35)
        enableCameraButtonView.defaultBackgroundColor = UIColor.whiteColor().alpha(0.3)
        enableCameraButtonView.layer.cornerRadius = 52
        enableCameraButtonView.layer.borderColor = UIColor.whiteColor().CGColor
        enableCameraButtonView.layer.borderWidth = 1.5
        enableCameraButtonView.rac_hidden <~ viewModel.cameraPreviewEnabled.producer.map(negate)
        enableCameraButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "takePicture"))
        view.addSubview(enableCameraButtonView)
        
        enableCameraTextView.text = "Please take a preview picture"
        enableCameraTextView.font = UIFont.displayOfSize(14, withType: .Regular)
        enableCameraTextView.textColor = .whiteColor()
        enableCameraTextView.rac_hidden <~ viewModel.cameraPreviewEnabled.producer.map(negate)
        view.addSubview(enableCameraTextView)
        
        submitButtonView.rac_hidden <~ viewModel.cameraPreviewEnabled
        submitButtonView.rac_userInteractionEnabled <~ viewModel.readyToSubmit
        submitButtonView.setTitle(String.iconWithName(.Check), forState: .Normal)
        submitButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        submitButtonView.defaultBackgroundColor = .Accent
        submitButtonView.disabledBackgroundColor = UIColor.Accent.alpha(0.5)
        submitButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        submitButtonView.layer.cornerRadius = 30
        submitButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "submit"))
        view.addSubview(submitButtonView)
        
        infoWrapperView.rac_alpha <~ viewModel.previewImageUrl.producer.map(isEmpty).map { $0 ? 0.2 : 1 }
        view.addSubview(infoWrapperView)
        
        locationIconView.text = String.iconWithName(.Location)
        locationIconView.font = UIFont.iconOfSize(15)
        locationIconView.rac_textColor <~ viewModel.locationEnabled.producer.map { $0 ? .DarkGrey : .Accent }
        infoWrapperView.addSubview(locationIconView)
        
        locationWarningView.text = "Location required"
        locationWarningView.textColor = .Accent
        locationWarningView.font = UIFont.displayOfSize(16.5, withType: .Thin)
        locationWarningView.rac_hidden <~ viewModel.locationEnabled
        infoWrapperView.addSubview(locationWarningView)
        
        locationEnableView.text = "enable now"
        locationEnableView.textColor =  .Accent
        locationEnableView.font = UIFont.displayOfSize(16.5, withType: .Semibold)
        locationEnableView.rac_hidden <~ viewModel.locationEnabled
        locationEnableView.userInteractionEnabled = true
        locationEnableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "enableLocation"))
        infoWrapperView.addSubview(locationEnableView)
        
        locationTextView.rac_text <~ viewModel.locationText
        locationTextView.rac_hidden <~ viewModel.locationEnabled.producer.map(negate)
        locationTextView.font = UIFont.displayOfSize(16.5, withType: .Semibold)
        locationTextView.textColor = .DarkGrey
        infoWrapperView.addSubview(locationTextView)
        
        locationCountryView.rac_text <~ viewModel.locationCountry
        locationCountryView.rac_hidden <~ viewModel.locationEnabled.producer.map(negate)
        locationCountryView.font = UIFont.displayOfSize(16.5, withType: .Thin)
        locationCountryView.textColor = .DarkGrey
        infoWrapperView.addSubview(locationCountryView)
        
        locationReloadView.text = String.iconWithName(.Redo)
        locationReloadView.textColor = .DarkGrey
        locationReloadView.font = UIFont.iconOfSize(14)
        locationReloadView.userInteractionEnabled = true
        locationReloadView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "reloadLocation"))
        locationReloadView.rac_hidden <~ viewModel.locationEnabled.producer.map(negate)
            .combineLatestWith(viewModel.locationLoading.producer).map(or)
        infoWrapperView.addSubview(locationReloadView)
        
        locationActivityView.activityIndicatorViewStyle = .Gray
        viewModel.locationLoading.producer.combineLatestWith(viewModel.locationEnabled.producer).map(and)
            .startWithNext { [weak self] loading in
                if loading {
                    self?.locationActivityView.startAnimating()
                } else {
                    self?.locationActivityView.stopAnimating()
                }
                self?.locationActivityView.hidden = !loading
            }
        infoWrapperView.addSubview(locationActivityView)
        
        hashtagInputView.size = .Medium
        hashtagInputView.color = .Dark
        hashtagInputView.rac_status <~ viewModel.hashtagStringStatus
        hashtagInputView.placeholder = "Hashtags"
        hashtagInputView.rac_textSignal().toSignalProducer().startWithNext { [weak self] val in
            self?.viewModel.hashtagString.value = val as! String
        }
        hashtagInputView.keyboardType = .Twitter
        hashtagInputView.autocorrectionType = .No
        infoWrapperView.addSubview(hashtagInputView)
        
        textInputView.font = UIFont.textOfSize(14, withType: .Regular)
        textInputView.placeholder = "Tell something about what you see..."
        viewModel.textEnabled.producer
            .startWithNext { [weak self] enabled in
                self?.textInputView.userInteractionEnabled = enabled
                self?.textInputView.placeholderColor = enabled ? UIColor.DarkGrey.alpha(0.4) : UIColor.DarkGrey.alpha(0.15)
            }
        textInputView.textColor = UIColor(0x4d4d4d)
        textInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        textInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        textInputView.returnKeyType = .Done
        textInputView.delegate = self
        textInputView.rac_textSignal().toSignalProducer().startWithNext { [weak self] val in
            self?.viewModel.text.value = val as! String
        }
        infoWrapperView.addSubview(textInputView)
        
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
        
        cancelButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: previewImageView, withOffset: 30)
        cancelButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 20)
        
        enableCameraButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: previewImageView)
        enableCameraButtonView.autoAlignAxis(.Horizontal, toSameAxisOfView: previewImageView, withOffset: -10)
        enableCameraButtonView.autoSetDimension(.Height, toSize: 104)
        enableCameraButtonView.autoSetDimension(.Width, toSize: 104)
        
        enableCameraTextView.autoAlignAxis(.Vertical, toSameAxisOfView: previewImageView)
        enableCameraTextView.autoPinEdge(.Top, toEdge: .Bottom, ofView: enableCameraButtonView, withOffset: 20)
        
        submitButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView, withOffset: -20)
        submitButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: previewImageView, withOffset: -20)
        submitButtonView.autoSetDimension(.Width, toSize: 60)
        submitButtonView.autoSetDimension(.Height, toSize: 60)
        
        infoWrapperView.autoPinEdge(.Left, toEdge: .Left, ofView: view)
        infoWrapperView.autoPinEdge(.Right, toEdge: .Right, ofView: view)
        infoWrapperView.autoPinEdge(.Top, toEdge: .Top, ofView: locationIconView)
        infoWrapperView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: textInputView)
        
        locationIconView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 20)
        locationIconView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
        locationIconView.autoSetDimension(.Width, toSize: 15)
        locationIconView.autoSetDimension(.Height, toSize: 15)
        
        locationWarningView.autoPinEdge(.Top, toEdge: .Top, ofView: locationIconView, withOffset: -2)
        locationWarningView.autoPinEdge(.Left, toEdge: .Right, ofView: locationIconView, withOffset: 4)
        
        locationEnableView.autoPinEdge(.Top, toEdge: .Top, ofView: locationWarningView)
        locationEnableView.autoPinEdge(.Left, toEdge: .Right, ofView: locationWarningView, withOffset: 5)
        
        locationTextView.autoPinEdge(.Top, toEdge: .Top, ofView: locationWarningView)
        locationTextView.autoPinEdge(.Left, toEdge: .Left, ofView: locationWarningView)
        
        locationCountryView.autoPinEdge(.Top, toEdge: .Top, ofView: locationWarningView)
        locationCountryView.autoPinEdge(.Left, toEdge: .Right, ofView: locationTextView, withOffset: 5)
        
        locationReloadView.autoPinEdge(.Top, toEdge: .Top, ofView: locationTextView, withOffset: 3)
        locationReloadView.autoPinEdge(.Left, toEdge: .Right, ofView: locationCountryView, withOffset: 13)
        
        locationActivityView.autoPinEdge(.Top, toEdge: .Top, ofView: locationTextView, withOffset: 1)
        locationActivityView.autoPinEdge(.Left, toEdge: .Right, ofView: locationCountryView, withOffset: 10)
        
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
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.CreateOptograph")
        Mixpanel.sharedInstance().timeEvent("Action.CreateOptograph.Cancel")
        
        // needed if user re-enabled location via Settings.app
        reloadLocation()
        
        session.startRunning()
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
        
        session.commitConfiguration()
    }
    
    func cancel() {
        Mixpanel.sharedInstance().track("Action.CreateOptograph.Cancel")
        
        if StitchingService.isStitching() {
            StitchingService.cancelStitching()
        }
        // No if here explicitely. If the stitching service has no 
        // unstitched recordings, it's not allowed in this view. 
        StitchingService.removeUnstitchedRecordings()
        
        navigationController?.popViewControllerAnimated(false)
    }
    
    func submit() {
        viewModel.post()
        PipelineService.check()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func enableLocation() {
        viewModel.enableLocation()
    }
    
    func reloadLocation() {
        viewModel.locationSignal.notify()
    }
    
    func takePicture() {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            imagePickerController.sourceType = .Camera
        } else if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            // just for simulator debugging
            imagePickerController.sourceType = .PhotoLibrary
        }
        
        imagePickerController.delegate = self
        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}

// MARK: - UITextFieldDelegate
extension CreateOptographViewController: UITextViewDelegate {

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            view.endEditing(true)
            return false
        }
        return true
    }
    
}

// MARK: - UIImagePickerControllerDelegate
extension CreateOptographViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        session.stopRunning()
        
        viewModel.cameraPreviewEnabled.value = false
        
        imagePickerController.dismissViewControllerAnimated(true, completion: nil)
    
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        let fixedImage = image.fixedOrientation()
        let imageData = UIImageJPEGRepresentation(fixedImage, 0.7)!
        viewModel.optograph.saveAsset(.PreviewImage(imageData))
        viewModel.updatePreviewImage()
    }
    
}
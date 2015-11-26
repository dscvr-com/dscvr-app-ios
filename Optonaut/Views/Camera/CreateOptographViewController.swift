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

class CreateOptographViewController: UIViewController {
    
    private let viewModel = CreateOptographViewModel()
    
    // camera
    private let session = AVCaptureSession()
    private let sessionQueue: dispatch_queue_t
    private let recorderQueue: dispatch_queue_t
    
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
    private let locationEnableView = BoundingLabel()
    private let locationReloadView = UILabel()
    private let locationActivityView = UIActivityIndicatorView()
    private let descriptionView = ActiveLabel()
    private let textInputView = KMPlaceholderTextView()
    private let hashtagInputView = LineTextField()
    private let lockIconView = BoundingLabel()
    private let lockTextView = BoundingLabel()
    private let backgroundView = BackgroundView()
    
    private let imagePickerController = UIImagePickerController()
    
    required init(recorderCleanup: SignalProducer<Void, NoError>) {
        let high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        sessionQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
        dispatch_set_target_queue(sessionQueue, high)
        
        recorderQueue = dispatch_queue_create("recorderQueue", DISPATCH_QUEUE_SERIAL)
        
        super.init(nibName: nil, bundle: nil)
        
        recorderCleanup
            .startOn(QueueScheduler(queue: recorderQueue))
            .startWithCompleted { [weak self] in
                self?.viewModel.recorderCleanedUp.value = true
            }
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
        
        submitButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        submitButtonView.defaultBackgroundColor = .Accent
        submitButtonView.disabledBackgroundColor = UIColor.Accent.alpha(0.5)
        submitButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        submitButtonView.layer.cornerRadius = 30
        submitButtonView.rac_hidden <~ viewModel.cameraPreviewEnabled
        submitButtonView.rac_userInteractionEnabled <~ viewModel.readyToSubmit
        submitButtonView.rac_loading <~ viewModel.recorderCleanedUp.producer.map(negate)
        submitButtonView.rac_title <~ viewModel.recorderCleanedUp.producer.mapToTuple(String.iconWithName(.Check), "")
        submitButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "submit"))
        view.addSubview(submitButtonView)
        
        infoWrapperView.rac_alpha <~ viewModel.previewImageUrl.producer.map(isEmpty).map { $0 ? 0.2 : 1 }
        view.addSubview(infoWrapperView)
        
        locationIconView.text = String.iconWithName(.Location)
        locationIconView.font = UIFont.iconOfSize(15)
        locationIconView.rac_textColor <~ viewModel.locationEnabled.producer.map { $0 ? .DarkGrey : .Accent }
        infoWrapperView.addSubview(locationIconView)
        
        locationWarningView.text = "Use Location"
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
        hashtagInputView.delegate = self
        hashtagInputView.addTarget(self, action: "textFieldChanged", forControlEvents: .EditingChanged)
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
        
        lockIconView.rac_text <~ viewModel.isPrivate.producer.mapToTuple(.iconWithName(.Locked), .iconWithName(.Unlocked))
        lockIconView.textColor = .LightGrey
        lockIconView.font = UIFont.iconOfSize(15)
        lockIconView.userInteractionEnabled = true
        lockIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "togglePrivate"))
        backgroundView.addSubview(lockIconView)
        
        lockTextView.rac_text <~ viewModel.isPrivate.producer.mapToTuple("Optograph will be private", "Optograph will be public")
        lockTextView.textColor = .LightGrey
        lockTextView.font = UIFont.displayOfSize(14, withType: .Semibold)
        lockTextView.userInteractionEnabled = true
        lockTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "togglePrivate"))
        backgroundView.addSubview(lockTextView)
        
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
        
        lockIconView.autoPinEdge(.Top, toEdge: .Top, ofView: backgroundView, withOffset: 25)
        lockIconView.autoPinEdge(.Left, toEdge: .Left, ofView: backgroundView, withOffset: 19)
        lockIconView.autoSetDimension(.Width, toSize: 15)
        lockIconView.autoSetDimension(.Height, toSize: 15)
        
        lockTextView.autoPinEdge(.Top, toEdge: .Top, ofView: lockIconView, withOffset: 0)
        lockTextView.autoPinEdge(.Left, toEdge: .Right, ofView: lockIconView, withOffset: 7)
        
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
        
        // needed if user re-enabled location via Settings.app
        reloadLocation()
        
        if viewModel.cameraPreviewEnabled.value {
            session.startRunning()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        
        navigationController?.interactivePopGestureRecognizer?.enabled = true
        
        if viewModel.cameraPreviewEnabled.value {
            session.stopRunning()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.CreateOptograph")
        
        // TODO find better way to do this
        viewModel.locationPermissionTimer?.invalidate()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        view.frame.origin.y = -keyboardHeight
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
        
        navigationController?.popViewControllerAnimated(false)
    }
    
    func submit() {
        Mixpanel.sharedInstance().track("Action.CreateOptograph.Post")
        viewModel.post()
        PipelineService.check()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func enableLocation() {
        viewModel.enableLocation()
    }
    
    func reloadLocation() {
        viewModel.locationSignal.notify(())
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
    
    func textFieldChanged() {
        prependHashtag()
    }
    
    func togglePrivate() {
        let settingsSheet = UIAlertController(title: "Set visibility", message: "Who should be able to see your Optograph?", preferredStyle: .ActionSheet)
        
        settingsSheet.addAction(UIAlertAction(title: "Everybody (Default)", style: .Default, handler: { [weak self] _ in
            self?.viewModel.isPrivate.value = false
        }))
        
        settingsSheet.addAction(UIAlertAction(title: "Just me", style: .Destructive, handler: { [weak self] _ in
            self?.viewModel.isPrivate.value = true
        }))
        
        settingsSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        
        navigationController?.presentViewController(settingsSheet, animated: true, completion: nil)
    }
    
}

// MARK: - UITextFieldDelegate
extension CreateOptographViewController: UITextFieldDelegate {
    
    private func prependHashtag() {
        let text = hashtagInputView.text ?? ""
        let previousText = hashtagInputView.previousText ?? ""
        
        if (text.isEmpty || text.characters.last == " ") && text.characters.count >= previousText.characters.count {
            hashtagInputView.text = text + "#"
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        prependHashtag()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if hashtagInputView.text == "#" {
            hashtagInputView.text = ""
            hashtagInputView.previousText = ""
        }
    }
    
}


// MARK: - UITextViewDelegate
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
        
        viewModel.cameraPreviewEnabled.value = false
        
        imagePickerController.dismissViewControllerAnimated(true, completion: nil)
    
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        let fixedImage = image.fixedOrientation()
        let imageData = UIImageJPEGRepresentation(fixedImage, 0.7)!
        viewModel.optograph.saveAsset(.PreviewImage(imageData))
        viewModel.updatePreviewImage()
    }
    
}
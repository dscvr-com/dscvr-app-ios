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
import Crashlytics
import ActiveLabel
import PermissionScope
import AVFoundation

class CreateOptographViewController: UIViewController, RedNavbar {
    
    let viewModel = CreateOptographViewModel()
    
    // camera
    private let session = AVCaptureSession()
    private let sessionQueue: dispatch_queue_t = {
        let queue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
        let high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        dispatch_set_target_queue(queue, high)
        return queue
    }()
    private let stillImageOutput = AVCaptureStillImageOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // subviews
    let previewImageView = PlaceholderImageView()
    let cameraButtonView = HatchedButton()
    let locationView = InsetLabel()
    let descriptionView = ActiveLabel()
    let textInputView = KMPlaceholderTextView()
    let hashtagInputView = KMPlaceholderTextView()
    let lineView = UIView()
    
    var stitcherDisposable: Disposable?
    
    let assetSignalProducer: SignalProducer<OptographAsset, NoError>
    
    required init(assetSignalProducer: SignalProducer<OptographAsset, NoError>) {
        self.assetSignalProducer = assetSignalProducer
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pscope = PermissionScope()
        
        pscope.headerLabel.text = "Where are you?"
        pscope.bodyLabel.text = "Please share your location\r\nto tag your Optograph"
        pscope.unauthorizedButtonColor = UIColor.Accent
        pscope.permissionButtonTextColor = UIColor.Accent
        pscope.permissionButtonBorderColor = UIColor.Accent
        pscope.permissionLabelColor = UIColor(0x4d4d4d)
        pscope.closeButton.titleLabel?.font = UIFont.icomoonOfSize(30)
        pscope.closeButton.setTitle(String.icomoonWithName(.Cross), forState: .Normal)
        pscope.closeButtonTextColor = UIColor(0x4d4d4d)
        pscope.closeOffset = CGSize(width: 7, height: 5)
        
        pscope.addPermission(LocationWhileInUsePermission(), message: "This step is just needed once")
        
        pscope.show(
            { finished, results in },
            cancelled: { _ in
                self.navigationController?.popViewControllerAnimated(false)
            }
        )
        
        Answers.logCustomEventWithName("Camera", customAttributes: ["State": "Preparing"])
        
        view.backgroundColor = .whiteColor()
        
        let attributes = [NSFontAttributeName: UIFont.robotoOfSize(17, withType: .Regular)]
        
        let cancelButton = UIBarButtonItem()
        cancelButton.title = "Cancel"
        cancelButton.setTitleTextAttributes(attributes, forState: .Normal)
        cancelButton.target = self
        cancelButton.action = "cancel"
        navigationItem.setLeftBarButtonItem(cancelButton, animated: false)
        
        let postButton = UIBarButtonItem()
        postButton.title = "Post"
        postButton.setTitleTextAttributes(attributes, forState: .Normal)
        postButton.target = self
        postButton.action = "post"
        
        navigationItem.title = "New Optograph"
        
        let spinnerView = UIActivityIndicatorView()
        let spinnerButton = UIBarButtonItem(customView: spinnerView)
        
        viewModel.pending.producer.startWithNext { pending in
            if pending {
                self.navigationItem.setRightBarButtonItem(spinnerButton, animated: true)
                spinnerView.startAnimating()
            } else {
                self.navigationItem.setRightBarButtonItem(postButton, animated: true)
                spinnerView.stopAnimating()
            }
        }
        
        previewImageView.placeholderImage = UIImage(named: "optograph-placeholder")!
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.rac_url <~ viewModel.previewImageUrl
        previewImageView.rac_hidden <~ viewModel.cameraPreviewEnabled
        view.addSubview(previewImageView)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        viewModel.cameraPreviewEnabled.producer.startWithNext { enabled in
            self.previewLayer?.opacity = enabled ? 1 : 0
        }
        view.layer.addSublayer(previewLayer!)
        
        cameraButtonView.setTitle(String.icomoonWithName(.Camera), forState: .Normal)
        cameraButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        cameraButtonView.defaultBackgroundColor = .Accent
        cameraButtonView.titleLabel?.font = UIFont.icomoonOfSize(20)
        cameraButtonView.layer.cornerRadius = 30
        cameraButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleCamera"))
        view.addSubview(cameraButtonView)
        
        locationView.rac_text <~ viewModel.location
        locationView.rac_hidden <~ viewModel.location.producer.map { $0.isEmpty }
        locationView.font = UIFont.robotoOfSize(12, withType: .Regular)
        locationView.textColor = .whiteColor()
        locationView.backgroundColor = UIColor(0x0).alpha(0.4)
        locationView.edgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        view.addSubview(locationView)
        
        hashtagInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        hashtagInputView.placeholder = "Provide at least one hashtag. Example: #nature #mountains"
        hashtagInputView.placeholderColor = UIColor(0xcfcfcf)
        hashtagInputView.textColor = UIColor(0x4d4d4d)
        hashtagInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.hashtagString.value = $0 as! String }
        hashtagInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        hashtagInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        textInputView.keyboardType = .Twitter
        view.addSubview(hashtagInputView)
        
        textInputView.font = UIFont.robotoOfSize(15, withType: .Regular)
        textInputView.placeholder = "Enter a description here..."
        textInputView.placeholderColor = UIColor(0xcfcfcf)
        textInputView.textColor = UIColor(0x4d4d4d)
        textInputView.rac_textSignal().toSignalProducer().startWithNext { self.viewModel.text.value = $0 as! String }
        textInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        textInputView.textContainerInset = UIEdgeInsetsZero // remove top padding
        textInputView.keyboardType = .Twitter
        view.addSubview(textInputView)
        
        lineView.backgroundColor = UIColor(0xe5e5e5)
        view.addSubview(lineView)
        
        setupCamera()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        stitcherDisposable = assetSignalProducer
            .startOn(QueueScheduler(queue: dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)))
            .on(next: { asset in
                self.viewModel.saveAsset(asset)
            })
            .observeOn(UIScheduler())
            .on(completed: {
                self.viewModel.pending.value = false
            })
            .start()
        
        // TODO make signalproducer to optional -> set to nil
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewLayer?.frame = previewImageView.frame
    }
    
    override func updateViewConstraints() {
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: view, withMultiplier: 3 / 4)
        
        cameraButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView, withOffset: -20)
        cameraButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: previewImageView, withOffset: -20)
        cameraButtonView.autoSetDimension(.Width, toSize: 60)
        cameraButtonView.autoSetDimension(.Height, toSize: 60)
        
        locationView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView, withOffset: -13)
        locationView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
        
        hashtagInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 20)
        hashtagInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        hashtagInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        hashtagInputView.autoSetDimension(.Height, toSize: 50)
        
        textInputView.autoPinEdge(.Top, toEdge: .Bottom, ofView: hashtagInputView, withOffset: 20)
        textInputView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        textInputView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        textInputView.autoSetDimension(.Height, toSize: 100)
        
        lineView.autoPinEdge(.Top, toEdge: .Bottom, ofView: textInputView, withOffset: 5)
        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        lineView.autoSetDimension(.Height, toSize: 1)
        
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
        stitcherDisposable?.dispose()
        navigationController?.popViewControllerAnimated(false)
    }
    
    func post() {
        if viewModel.previewImageUrl.value.isEmpty {
            return
        }
        
        Answers.logCustomEventWithName("Camera", customAttributes: ["State": "Posting"])
        
        viewModel.post().startWithNext { optograph in
            self.navigationController?.pushViewController(DetailsTableViewController(optographId: optograph.id), animated: false)
            self.navigationController?.viewControllers.removeAtIndex(1)
        }
    }
    
    func toggleCamera() {
        if viewModel.cameraPreviewEnabled.value {
            if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
                stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                    (imageDataSampleBuffer, error) -> Void in
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let previewImage = OptographAsset.PreviewImage(imageData)
                    self.viewModel.saveAsset(previewImage)
                }
            }
        } else {
            
        }
        viewModel.cameraPreviewEnabled.value = !viewModel.cameraPreviewEnabled.value
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
}
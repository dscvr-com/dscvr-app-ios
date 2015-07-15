//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import AVFoundation
import ReactiveCocoa

class CameraViewController: UIViewController {
    
    var stillImageOutput: AVCaptureStillImageOutput!
    var session: AVCaptureSession!
    
    let viewModel = CameraViewModel()
    
    // subviews
    let closeButtonView = UIButton()
    let instructionView = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCamera()
        
        closeButtonView.setTitle(String.icomoonWithName(.Cross), forState: .Normal)
        closeButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        closeButtonView.titleLabel?.font = .icomoonOfSize(40)
        closeButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.navigationController?.popViewControllerAnimated(false)
            return RACSignal.empty()
        })
        view.addSubview(closeButtonView)
        
        instructionView.font = UIFont.robotoOfSize(17, withType: .Regular)
        instructionView.textColor = .whiteColor()
        instructionView.textAlignment = .Center
        instructionView.rac_text <~ viewModel.instruction
        instructionView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        view.addSubview(instructionView)
        
        viewModel.instruction.put("Select")
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.tabBar.hidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
    }
    
    override func updateViewConstraints() {
        closeButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: 29) // tab bar height is 49pt
        closeButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
        
        instructionView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 35)
        instructionView.autoAlignAxis(.Horizontal, toSameAxisOfView: view)
        
        super.updateViewConstraints()
    }
    
    private func configureCamera() {
        // init camera device
        var captureDevice: AVCaptureDevice?
        let devices = AVCaptureDevice.devices()
        
        // find back camera
        for device in devices {
            if device.position == AVCaptureDevicePosition.Back {
                captureDevice = device as? AVCaptureDevice
            }
        }
        
        // init device input
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice)
        
        stillImageOutput = AVCaptureStillImageOutput()
        
        // init session
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        session.addInput(deviceInput)
        session.addOutput(stillImageOutput)
        
        // layer for preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer)
        
//        let blurEffect = UIBlurEffect(style: .Dark)
//        let blurView = UIVisualEffectView(effect: blurEffect)
//        blurView.frame = view.bounds
//        view.addSubview(blurView)
//        view.clipsToBounds = true
//        view.contentMode = UIViewContentMode.ScaleAspectFill
        
        session.startRunning()
    }
    
}

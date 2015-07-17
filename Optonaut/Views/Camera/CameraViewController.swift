//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
import CoreGraphics
import ReactiveCocoa
import Alamofire
import SceneKit

class CameraViewController: UIViewController {
    
    let viewModel = CameraViewModel()
    
    let motionManager = CMMotionManager()
    
    var session: AVCaptureSession!
    var sessionQueue: dispatch_queue_t!
    var videoDeviceInput: AVCaptureDeviceInput!
    var videoDeviceOutput: AVCaptureVideoDataOutput!
    
    // debug
    let writeToDisk = false
    let timestamp = NSDate().timeIntervalSince1970
    var count = 0
    
    // subviews
    let closeButtonView = UIButton()
    let instructionView = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetHigh
        
        sessionQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
        
//        let blurEffect = UIBlurEffect(style: .Dark)
//        let blurView = UIVisualEffectView(effect: blurEffect)
//        blurView.frame = view.bounds
//        view.addSubview(blurView)
//        view.clipsToBounds = true
//        view.contentMode = UIViewContentMode.ScaleAspectFill
        
        // layer for preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.frame = self.view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(previewLayer)
        
        closeButtonView.setTitle(String.icomoonWithName(.Cross), forState: .Normal)
        closeButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        closeButtonView.titleLabel?.font = .icomoonOfSize(40)
        closeButtonView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
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
        
        dispatch_async(sessionQueue, {
            self.authorizeCamera()
            self.session.beginConfiguration()
            self.addVideoInput()
            self.addVideoOutput()
            self.session.commitConfiguration()
        })
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.tabBar.hidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
        
        motionManager.startDeviceMotionUpdates()
        
        dispatch_async(sessionQueue, {
            self.session.startRunning()
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        
        motionManager.stopDeviceMotionUpdates()
        session.stopRunning()
    }
    
    override func updateViewConstraints() {
        view.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero) // needed to cover tabbar (49pt)
        
        closeButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -20)
        closeButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
        
        instructionView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 35)
        instructionView.autoAlignAxis(.Horizontal, toSameAxisOfView: view)
        
        super.updateViewConstraints()
    }
    
    private func authorizeCamera() {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { granted in
            if !granted {
                dispatch_async(dispatch_get_main_queue(), {
                    UIAlertView(
                        title: "Could not use camera!",
                        message: "This application does not have permission to use camera. Please update your privacy settings.",
                        delegate: self,
                        cancelButtonTitle: "OK").show()
                })
            }
        });
    }
    
    private func addVideoInput() {
        let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        videoDeviceInput = try! AVCaptureDeviceInput(device: videoDevice)
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        }
    }
    
    private func addVideoOutput() {
        
        videoDeviceOutput = AVCaptureVideoDataOutput()
        
        videoDeviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
        
        videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
        
        videoDeviceOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if session.canAddOutput(videoDeviceOutput) {
            session.addOutput(videoDeviceOutput)
        }
    }
 
    private func processSampleBuffer(sampleBuffer: CMSampleBufferRef) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        if let pixelBuffer = pixelBuffer, motion = self.motionManager.deviceMotion {
            
            CVPixelBufferLockBaseAddress(pixelBuffer, .allZeros)
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .allZeros)
            
            let r = motion.attitude.rotationMatrix
            let extrinsics = [r.m11, r.m12, r.m13,
                              r.m21, r.m22, r.m23,
                              r.m31, r.m32, r.m33]
            let extrinsicsPointer = UnsafeMutablePointer<Double>.alloc(9)
            extrinsicsPointer.initializeFrom(extrinsics)
            
            let intrinsics = [4.854369, 0, 3,
                              0, 4.854369, 2.4,
                              0, 0, 1]
            let intrinsicsPointer = UnsafeMutablePointer<Double>.alloc(9)
            intrinsicsPointer.initializeFrom(intrinsics)
            
            let newExtrinsicsPointer = UnsafeMutablePointer<Double>.alloc(16)
            
            Stitcher.Push(extrinsicsPointer, intrinsicsPointer, baseAddress, Int32(width), Int32(height), newExtrinsicsPointer, Int32(0))
            
            let rotationMatrix = Array(UnsafeBufferPointer(start: newExtrinsicsPointer, count: 16))
            print(rotationMatrix)
        
            
            // DEBUG BEGIN
            if self.writeToDisk {
                let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, .AllDomainsMask, true)[0]
                let path = dir.stringByAppendingPathComponent("\(self.timestamp)/")
                try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
                
                let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
                let imgData = NSData(bytes: baseAddress, length: height * bytesPerRow)
                imgData.writeToFile(path.stringByAppendingPathComponent("\(self.count).bin"), atomically: false)
                try! " ".join(extrinsics.map { "\($0)" }).writeToFile(path.stringByAppendingPathComponent("\(self.count).ext"), atomically: false, encoding: NSUTF8StringEncoding)
                try! " ".join(intrinsics.map { "\($0)" }).writeToFile(path.stringByAppendingPathComponent("\(self.count).int"), atomically: false, encoding: NSUTF8StringEncoding)
                self.count++
            }
            // DEBUG END
        }
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        processSampleBuffer(sampleBuffer)
    }
}
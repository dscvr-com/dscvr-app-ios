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
    
    // camera
    var session: AVCaptureSession!
    var sessionQueue: dispatch_queue_t!
    var videoDeviceInput: AVCaptureDeviceInput!
    var videoDeviceOutput: AVCaptureVideoDataOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var scnView: SCNView!
    
    // stitcher pointer and variables
    
    let stitcher = IosPipeline()
    
    var frameCount = 0
    let intrinsics = CameraIntrinsics
    
    
    var debugHelper: CameraDebugHelper?
    var points = [Int32: SCNNode]()
    
    // subviews
    let closeButtonView = UIButton()
    let instructionView = UILabel()
    
    // sphere
    let cameraNode = SCNNode()
    
    let scene = SCNScene()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPreset640x480
        
        sessionQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
        
        
        //stitcher.EnableDebug(NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])
        
        // layer for preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        
        view.layer.addSublayer(previewLayer)
        view.addSubview(blurView)
        
        setupScene()
        setupSelectionPoints();
        
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
        
        viewModel.instruction.value = "Select"
        
        dispatch_async(sessionQueue) {
            self.authorizeCamera()
            self.session.beginConfiguration()
            self.addVideoInput()
            self.addVideoOutput()
            self.session.commitConfiguration()
        }
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.tabBar.hidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
        
        if viewModel.debugEnabled.value {
            debugHelper = CameraDebugHelper()
        }
        
        frameCount = 0
        
//        motionManager.startDeviceMotionUpdates()
        motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryCorrectedZVertical)
        
        dispatch_async(sessionQueue) {
            self.session.startRunning()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        
        debugHelper?.cleanup()
        
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
    
    private func setupScene() {
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 10000
        camera.xFov = 65
        camera.yFov = 65 * Double(view.bounds.height / view.bounds.width)
        
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        scene.rootNode.addChildNode(cameraNode)
        
        scnView = SCNView()
        scnView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        scnView.backgroundColor = UIColor.clearColor()
        scnView.scene = scene
        scnView.playing = true
        scnView.delegate = self
        
        view.addSubview(scnView)
    }
    
    private func setupSelectionPoints() {
        print("Adding points")
        for wrapped in stitcher.GetSelectionPoints() {
            var point = SelectionPoint()
            wrapped.getValue(&point)
            
            let scnGeometey = SCNSphere(radius: 0.02)
            scnGeometey.firstMaterial?.diffuse.contents = UIColor.orangeColor()
            scnGeometey.firstMaterial?.doubleSided = true
            
            
            let scnNode = SCNNode(geometry: scnGeometey)
            let translation = GLKMatrix4MakeTranslation(0, 0, -1)
            let res = GLKMatrix4Multiply(point.extrinsics, translation)
            scnNode.transform = SCNMatrix4FromGLKMatrix4(res)
            
            print("Adding Point")
            points[point.id] = scnNode
        
            scene.rootNode.addChildNode(scnNode)

        }
    }
    
    private func authorizeCamera() {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { granted in
            if !granted {
                dispatch_async(dispatch_get_main_queue()) {
                    UIAlertView(
                        title: "Could not use camera!",
                        message: "This application does not have permission to use camera. Please update your privacy settings.",
                        delegate: self,
                        cancelButtonTitle: "OK").show()
                }
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
            
            let r = CMRotationToGLKMatrix4(motion.attitude.rotationMatrix)
            CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
            
            var buf = ImageBuffer()
            buf.data = CVPixelBufferGetBaseAddress(pixelBuffer)
            buf.width = Int32(CVPixelBufferGetWidth(pixelBuffer))
            buf.height = Int32(CVPixelBufferGetHeight(pixelBuffer))
            
            print("Push!");

            stitcher.Push(r, buf)
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
            
            if(stitcher.IsPreviewImageValialble()) {
                
                let previewData = stitcher.GetPreviewImage()
                
                let currentPoint = stitcher.ClosestPoint()
                let nodeToRemove = points[currentPoint.id]
                nodeToRemove?.removeFromParentNode()
                points.removeValueForKey(currentPoint.id)
                print("Preview Image!");
            
                let cgImage = ImageBufferToCGImage(previewData);
                
                let ratio = CGFloat(previewData.height) / CGFloat(previewData.width)
                let planeGeometry = SCNPlane(width: CGFloat(1), height: ratio)
                planeGeometry.firstMaterial?.doubleSided = true
                planeGeometry.firstMaterial?.diffuse.contents = cgImage
                
                let planeNode = SCNNode(geometry: planeGeometry)
                
                let L = GLKMatrix4MakeRotation(Float(M_PI_2), 0, 0, -1)
                let R = stitcher.GetCurrentRotation()
                
                let T = GLKMatrix4MakeTranslation(0, 0, -Float(intrinsics[0]))
                let TL = GLKMatrix4Multiply(T, L)
                planeNode.transform = SCNMatrix4FromGLKMatrix4(GLKMatrix4Multiply(R, TL))
                
                scene.rootNode.addChildNode(planeNode)
                
                stitcher.FreeImageBuffer(previewData)
                stitcher.DisableSelectionPoint(currentPoint)
                
                if(points.count <= 1) {
                    finish()
                }
            }
            //debugHelper?.push(pixelBuffer, intrinsics: self.intrinsics, extrinsics: CMRotationToDoubleArray(motion.attitude.rotationMatrix), frameCount: frameCount)

        }
    }
    
    private func finish() {
        
        //This code can (and should be executed asynchronously while the user enters
        //the description.
        print("Finalizing");
        
        let leftBuffer = stitcher.GetLeftResult()
        let rightBuffer = stitcher.GetRightResult()
        let left = ImageBufferToCGImage(leftBuffer)
        let right = ImageBufferToCGImage(rightBuffer)
        
        upload(left, rightImage: right);
        
        stitcher.FreeImageBuffer(leftBuffer);
        stitcher.FreeImageBuffer(rightBuffer);
    }
    
    func upload(leftImage: CGImage, rightImage: CGImage) {
        print("Uploading");
        
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        saveCGImage(leftImage, path: path + "/left.jpg")
        saveCGImage(rightImage, path: path + "/right.jpg")
    }
    
    func saveCGImage(image: CGImage, path: String) {
        let i = UIImagePNGRepresentation(UIImage(CGImage: image))
        i!.writeToFile(path, atomically: true)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        processSampleBuffer(sampleBuffer)
        frameCount++
    }
}

// MARK: - SCNSceneRendererDelegate
extension CameraViewController: SCNSceneRendererDelegate {
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        if let motion = self.motionManager.deviceMotion {
            
            let rGlk = CMRotationToGLKMatrix4(motion.attitude.rotationMatrix);
            
            self.cameraNode.transform = SCNMatrix4FromGLKMatrix4(rGlk)
        
        }
    }
    
}
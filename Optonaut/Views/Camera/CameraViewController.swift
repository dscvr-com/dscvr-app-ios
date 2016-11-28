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
import Result
import Alamofire
import SceneKit
import Async
import Mixpanel
import SwiftyUserDefaults
import Photos
import CoreBluetooth

struct staticVariables {
    static var isCenter:Bool!
}

class CameraViewController: UIViewController,TabControllerDelegate ,CBPeripheralDelegate{
    
    private let viewModel = CameraViewModel()
    private let motionManager = CoreMotionRotationSource()
    private let rotationSource = CustomRotationMatrixSource.Instance
    
    // camera
    private let session = AVCaptureSession()
    private let sessionQueue: dispatch_queue_t
    private var videoDevice : AVCaptureDevice?
    
    private var lastExposureInfo = ExposureInfo()
    private var lastAwbGains = AVCaptureWhiteBalanceGains()
    private var exposureDuration:Double = 1
    private var captureWidth = Int(1)
    
    private let sensorWidthInMeters = Double(0.004)
    private let estimatedArmLengthInMeters = Double(0.50)
    
    // stitcher pointer and variables
    private var recorder: Recorder!
    private var frameCount = 0
    private var debugCount = 0
    private var previewImageCount = 0
    private let intrinsics = CameraIntrinsics
    private var lastKeyframe: SelectionPoint?
    
    // lines
    private var edges: [Edge: SCNNode] = [:]
    private let screenScale : Float
    private let lineWidth = Float(3)
    
    // subviews
    private let tiltView = TiltView()
    private let progressView = CameraProgressView()
    private let instructionView = UILabel()
    private let circleView = DashedCircleView()
    private let arrowView = UILabel()
    
    // sphere
    private let cameraNode = SCNNode()
    private var scnView : SCNView!
    private let scene = SCNScene()
    //for motor
    private var currentDegree : Float
    private var DegreeIncrPerMicro : Double
    var ringFlag = 0
    
    // ball
    private let ballNode = SCNNode()
    private var ballSpeed = GLKVector3Make(0, 0, 0)
    private let baseMatrix = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1 , 0.0, 0.0, -1.0, 0.00, 0.0, 0.0, 0.0, 0.0, 1.0)
    
    private var tapCameraButtonCallback: (() -> ())?
    private var lastElapsedTime = CACurrentMediaTime()
    private var currentTheta = Float(0.0)
    private var currentPhi = Float(0.0)
    
    private let cancelButton = UIButton()
    
    private let tabView = TabView()
    private let bData = BService.sharedInstance
    private var RotateData = String("")
    
    var timer = NSTimer()
    
    let sessionMotor = Defaults[.SessionMotor]
    
        
    required init() {
        
        currentDegree = 0.0
        DegreeIncrPerMicro = 0.0
        
        let high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        sessionQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
        dispatch_set_target_queue(sessionQueue, high)
        screenScale = Float(UIScreen.mainScreen().scale)
        
        if Defaults[.SessionDebuggingEnabled] {
            Recorder.enableDebug(CameraDebugService().path)
        }
        
        super.init(nibName: nil, bundle: nil)
        
        if sessionMotor {
            RotateData = self.computeRotationX()
        }
        
        tapCameraButtonCallback = { [weak self] in
            let confirmAlert = UIAlertController(title: "Hold the camera button", message: "In order to record please keep the camera button pressed", preferredStyle: .Alert)
            confirmAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            self?.presentViewController(confirmAlert, animated: true, completion: nil)
            
        }
    }
    
    func computeRotationX ( ) -> String {
        var rotateByteData:[UInt8] = [0xfe, 0x07, 0x01]
        
        // get number of rotation
        let xnumberSteps = Defaults[.SessionRotateCount]
        rotateByteData.append(UInt8(xnumberSteps! >> 24))
        rotateByteData.append(UInt8(xnumberSteps! >> 16))
        rotateByteData.append(UInt8(xnumberSteps! >> 8))
        rotateByteData.append(UInt8(xnumberSteps! & 0xff))
        print("rotateByteData1 \(rotateByteData)")
        // get pps
        let pps = Defaults[.SessionPPS]
        rotateByteData.append(UInt8(pps! >> 8))
        rotateByteData.append(UInt8(pps! & 0xff))
        // add full step
        rotateByteData.append(UInt8(0x00))
        let dataCheckSum = NSData(bytes: rotateByteData, length: rotateByteData.count)
        // compute for checksum
        rotateByteData.append(UInt8(self.checkSum(dataCheckSum)))
        print("rotateByteData \(rotateByteData)")
        // append padding
        rotateByteData.append(UInt8(0xff))
        rotateByteData.append(UInt8(0xff))
        rotateByteData.append(UInt8(0xff))
        rotateByteData.append(UInt8(0xff))
        rotateByteData.append(UInt8(0xff))
        rotateByteData.append(UInt8(0xff))
        // convert to hex string
        return self.hexString(NSData(bytes: rotateByteData, length: rotateByteData.count))
        
    }
    
    func checkSum(data: NSData) -> Int {
        let b = UnsafeBufferPointer<UInt8>(start:
            UnsafePointer(data.bytes), count: data.length)
        
        var sum = 0
        for i in 0..<data.length {
            sum += Int(b[i])
        }
        return sum & 0xff
    }
    func hexString(data:NSData)->String{
        if data.length > 0 {
            let  hexChars = Array("0123456789abcdef".utf8) as [UInt8];
            let buf = UnsafeBufferPointer<UInt8>(start: UnsafePointer(data.bytes), count: data.length);
            var output = [UInt8](count: data.length*2 + 1, repeatedValue: 0);
            var ix:Int = 0;
            for b in buf {
                let hi  = Int((b & 0xf0) >> 4);
                let low = Int(b & 0x0f);
                output[ix++] = hexChars[ hi];
                output[ix++] = hexChars[low];
            }
            let result = String.fromCString(UnsafePointer(output))!;
            return result;
        }
        return "";
    }
    func peripheral( peripheral: CBPeripheral,
                     didUpdateValueForCharacteristic characteristic: CBCharacteristic,
                                                     error: NSError?) {
        
        let responseData = characteristic.value
        print("reponsse data processed \(responseData)")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if Defaults[.SessionMotor] {
            rotationSource.stop()
        } else {
            motionManager.stop()
            
        }
        
        print("de init cameraviewcontroller")
        //rotationSource.stop()
        //motionManager.stopDeviceMotionUpdates()
        
        //We do that in our signal as soon as everything's finished
        //recorder.dispose()
        
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init scene view here because we need view bounds for the constructor overload
        // that forces GLES. Please don't use metal. It will fail.
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: view.bounds, options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
        } else {
            scnView = SCNView(frame: view.bounds)
        }
        
        // layer for preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        viewModel.tiltAngle.producer.startWithNext { [weak self] val in self?.tiltView.angle = val }
        viewModel.distXY.producer.startWithNext { [weak self] val in self?.tiltView.distXY = val }
        tiltView.innerRadius = 35
        view.addSubview(tiltView)
        
        viewModel.progress.producer.startWithNext { [weak self] val in self?.progressView.progress = val }
        viewModel.isRecording.producer.startWithNext { [weak self] val in self?.progressView.isActive = val}
        view.addSubview(progressView)
        
        instructionView.font = UIFont.robotoOfSize(22, withType: .Medium)
        instructionView.numberOfLines = 0
        instructionView.textColor = .whiteColor()
        instructionView.textAlignment = .Center
        instructionView.rac_text <~ viewModel.instruction
        view.addSubview(instructionView)
        
        circleView.layer.cornerRadius = 35
        viewModel.isRecording.producer.startWithNext { [weak self] val in self?.circleView.isDashed = !val }
        viewModel.isCentered.producer.startWithNext { [weak self] val in self?.circleView.isActive = val }
        view.addSubview(circleView)
        
        arrowView.text = String.iconWithName(.Next)
        arrowView.textColor = UIColor(hex:0xFF5E00)
        arrowView.textAlignment = .Center
        arrowView.font = UIFont.iconOfSize(40)
        arrowView.rac_alpha <~ viewModel.distXY.producer.map { distXY in
            let distLimit = Float(M_PI / 30)
            return 1 - max(CGFloat((distLimit - distXY) / distLimit + 1), 0)
        }
        viewModel.headingToDot.producer
            .map { CGAffineTransformMakeRotation(CGFloat($0) + CGFloat(M_PI_2)) }
            .startWithNext { [weak self] transform in self?.arrowView.transform = transform }
        view.addSubview(arrowView)
        
//        #if DEBUG
//            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.finish))
//            tapGestureRecognizer.numberOfTapsRequired = 3
//            view.addGestureRecognizer(tapGestureRecognizer)
//        #endif
        
        tabView.frame = CGRect(x: 0,y: view.frame.height - 126,width: view.frame.width,height: 126)
        scnView.addSubview(tabView)
        
        //motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        view.setNeedsUpdateConstraints()
        
        cancelButton.addTarget(self, action: #selector(CameraViewController.cancelRecording), forControlEvents: .TouchUpInside)
        cancelButton.setImage(UIImage(named: "camera_back_button"), forState: .Normal)
        scnView.addSubview(cancelButton)
        cancelButton.anchorInCorner(.TopLeft, xPad: 0, yPad: 15, width: 40, height: 40)
        
        //tabView.cameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapCameraButton)))
        //tabView.cameraButton.addTarget(self, action: #selector(touchStartCameraButton), forControlEvents: [.TouchDown])
        tabView.cameraButton.addTarget(self, action: #selector(tapCameraButton), forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
    }
    
    func tapCameraButton() {
        tabView.cameraButton.hidden = true
        viewModel.isRecording.value = true
        
        if sessionMotor {
            let rotatePlusBuff = (Defaults[.SessionRotateCount]! + Defaults[.SessionBuffCount]!)
            
            let missingSecs = 0.0
            DegreeIncrPerMicro = (0.036 / ( (Double(rotatePlusBuff) / Double(Defaults[.SessionPPS]!) ) - missingSecs ))
            //tabView.cameraButton.hidden = true
            //viewModel.isRecording.value = true
            
            if let bleService = btDiscoverySharedInstance.bleService {
                bleService.sendCommand(self.computeRotationX())
            }
        }
    }
    
    func touchEndCameraButton() {
        tapCameraButtonCallback = nil
    }
    
    func cancelRecording() {
        Mixpanel.sharedInstance().track("Action.Camera.CancelRecording")
        
        viewModel.isRecording.value = false
        tapCameraButtonCallback = nil
        
        if sessionMotor {
            if let bleService = btDiscoverySharedInstance.bleService {
                bleService.sendCommand("fe000402ffffffffffffffffffffffffff");
            }
        }
        
        stopSession()
        
        //recorder.getPreviewImage()
        
        recorder.finish()
        recorder.dispose()
        
        if StitchingService.hasUnstitchedRecordings() {
            StitchingService.removeUnstitchedRecordings()
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    private func setFocusMode(mode: AVCaptureFocusMode) {
        
        try! videoDevice!.lockForConfiguration()
        videoDevice!.focusMode = mode
        videoDevice!.unlockForConfiguration()
    }
    
    private func setExposureMode(mode: AVCaptureExposureMode) {
        try! videoDevice!.lockForConfiguration()
        
        if mode == AVCaptureExposureMode.Custom {
            exposureDuration = videoDevice!.exposureDuration.seconds
            var iso = videoDevice!.ISO
            if(iso > videoDevice!.activeFormat.maxISO) {
                iso = videoDevice!.activeFormat.maxISO
            }
            videoDevice?.setExposureModeCustomWithDuration(videoDevice!.exposureDuration, ISO: iso, completionHandler: nil)
        } else {
            videoDevice!.exposureMode = mode
        }
        videoDevice!.unlockForConfiguration()
        
        
//        do {
//            try videoDevice!.lockForConfiguration()
//            
//            if mode == AVCaptureExposureMode.Custom {
//                exposureDuration = videoDevice!.exposureDuration.seconds
//                var iso = videoDevice!.ISO
//                if(iso > videoDevice!.activeFormat.maxISO) {
//                    iso = videoDevice!.activeFormat.maxISO
//                }
//                videoDevice?.setExposureModeCustomWithDuration(videoDevice!.exposureDuration, ISO: iso, completionHandler: nil)
//            } else {
//                videoDevice!.exposureMode = mode
//            }
//            videoDevice!.unlockForConfiguration()
//        
//        } catch {
//            print("error on setExposureMode")
//        
//        }
    }
    
    private func setWhitebalanceMode(mode: AVCaptureWhiteBalanceMode) {
        try! videoDevice!.lockForConfiguration()
        videoDevice!.whiteBalanceMode = mode
        videoDevice!.unlockForConfiguration()
        
        
//        do {
//            try videoDevice!.lockForConfiguration()
//            videoDevice!.whiteBalanceMode = mode
//            videoDevice!.unlockForConfiguration()
//            
//        } catch {
//            print("setWhitebalanceMode")
//        }
    }
    
    
    private func setupSelectionPoints() {
        let rawPoints = recorder.getSelectionPoints()
        var points = [SelectionPoint]()
        
        while rawPoints.HasMore() {
            let point = rawPoints.Next()
            points.append(point)
        }
        
        var points2 = points;
        points2.removeAtIndex(0);
        
        var i = 0
        
        for (a, b) in zip(points, points2) {
            if a.ringId == b.ringId {
                let edge = Edge(a, b)
                
                let vec = GLKVector3Make(0, 0, -1)
                let posA = GLKMatrix4MultiplyVector3(a.extrinsics, vec)
                let posB = GLKMatrix4MultiplyVector3(b.extrinsics, vec)
                
                let edgeNode = createLineNode(posA, posB: posB)
                
                //                if i % 20 > 9 {
                //                    edgeNode.geometry!.firstMaterial!.diffuse.contents = UIColor.blackColor()
                //                }
                
                edges[edge] = edgeNode
                
                scene.rootNode.addChildNode(edgeNode)
                
                i += 1;
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        switch Defaults[.SessionUseMultiRing] {
        case true:
            self.recorder = Recorder(.Truncated)
        case false:
            self.recorder = Recorder(.Center)
        }
        
        
        setupScene()
        setupBall()
        setupSelectionPoints()
        setupCamera()
        
        // Locks the focus as soon as the user starts recording.
        // We do this to avoid re-focusing during recording, which breaks the Optograph
        
        viewModel.isRecording.producer
            .map { $0 ? .Locked : .ContinuousAutoFocus }
            .startWithNext { [unowned self] val in self.setFocusMode(val) }
        
        viewModel.isRecording.producer
            .filter { $0 }
            .take(1)
            .startWithNext { [unowned self] val in
                self.setExposureMode(.Custom)
                self.setWhitebalanceMode(.Locked)
        }
        
        updateTabs()
        
        tabController!.delegate = self
        
        Mixpanel.sharedInstance().timeEvent("View.Camera")
        
        viewModel.isRecording.producer.filter(identity).take(1).startWithNext { _ in
            Mixpanel.sharedInstance().track("Action.Camera.StartRecording")
        }
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
        
        
        frameCount = 0
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        if Defaults[.SessionMotor] {
             rotationSource.start()
           
        } else {
           motionManager.start()
        }
        //(.XArbitraryCorrectedZVertical)
        //motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryCorrectedZVertical)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        Mixpanel.sharedInstance().track("View.Camera")
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tabController!.disableScrollView()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        
        UIApplication.sharedApplication().idleTimerDisabled = false
    }
    
    override func updateViewConstraints() {
        view.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero) // needed to cover tabbar (49pt)
        
        tiltView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        progressView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 28)
        progressView.autoMatchDimension(.Width, toDimension: .Width, ofView: view, withOffset: -80)
        progressView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        
        instructionView.autoAlignAxis(.Horizontal, toSameAxisOfView: view, withMultiplier: 0.5)
        instructionView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        
        arrowView.autoAlignAxis(.Horizontal, toSameAxisOfView: view)
        arrowView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        arrowView.autoSetDimensionsToSize(CGSize(width: 70, height: 70))
        
        circleView.autoAlignAxis(.Horizontal, toSameAxisOfView: view)
        circleView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        circleView.autoSetDimensionsToSize(CGSize(width: 70, height: 70))
        
        //tabView.anchorAndFillEdge(.Top, xPad: 0, yPad: 0, otherSize: 126)
        tabView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view)
        tabView.autoMatchDimension(.Width, toDimension: .Width, ofView: view, withOffset:0)
        
        super.updateViewConstraints()
    }
    
    func updateTabs() {
        tabView.leftButton.hidden = true
        tabView.rightButton.hidden = true
    }
    
    private func setupScene() {
        let camera = SCNCamera()
        let fov = 45 as Double
        camera.zNear = 0.01
        camera.zFar = 10000
        camera.xFov = fov
        camera.yFov = fov * Double(view.bounds.width / 2 / view.bounds.height)
        
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        scene.rootNode.addChildNode(cameraNode)
        
        scnView.backgroundColor = UIColor.clearColor()
        scnView.scene = scene
        scnView.playing = true
        scnView.delegate = self
        
        view.addSubview(scnView)
    }
    
    private func createLineNode(posA: GLKVector3, posB: GLKVector3) -> SCNNode {
        let positions: [Float32] = [posA.x, posA.y, posA.z, posB.x, posB.y, posB.z]
        let positionData = NSData(bytes: positions, length: sizeof(Float32)*positions.count)
        let indices: [Int32] = [0, 1]
        let indexData = NSData(bytes: indices, length: sizeof(Int32) * indices.count)
        
        let source = SCNGeometrySource(data: positionData, semantic: SCNGeometrySourceSemanticVertex, vectorCount: indices.count, floatComponents: true, componentsPerVector: 3, bytesPerComponent: sizeof(Float32), dataOffset: 0, dataStride: sizeof(Float32) * 3)
        let element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.Line, primitiveCount: indices.count, bytesPerIndex: sizeof(Int32))
        
        let line = SCNGeometry(sources: [source], elements: [element])
        let node = SCNNode(geometry: line)
        
        line.firstMaterial?.diffuse.contents = UIColor.whiteColor()
        
        return node
    }
    
    private func setupBall() {
        
        let ballGeometry = SCNSphere(radius: CGFloat(0.04))
        
        ballNode.geometry = ballGeometry
        ballNode.geometry?.firstMaterial?.diffuse.contents = UIColor(hex:0xFF5E00)
        
        scene.rootNode.addChildNode(ballNode)
    }
    
    private var time = Double(-1)
    
    private func updateBallPosition(expTime:Double) {
        
        // Quick hack to limit expo duration in calculations, due to unexpected results of CACurrentMediaTime
        //let exposureDuration = max(self.exposureDuration, 0.006)
        
        let exposureDuration = max(self.exposureDuration, expTime)
        
        let ballSphereRadius = Float(0.9) // Don't put it on 1, since it would overlap with the rings then.
        let movementPerFrameInPixels = Double(1500)
        
        let newTime = CACurrentMediaTime()
        
        let vec = GLKVector3Make(0, 0, -ballSphereRadius)
        let target = GLKMatrix4MultiplyVector3(recorder.getBallPosition(), vec)
        
        let ball = SCNVector3ToGLKVector3(ballNode.position)
        
        //        if true || !recorder.hasStarted() {
        if !recorder.hasStarted() {
            ballNode.position = SCNVector3FromGLKVector3(target)
        } else {
            // Speed per second
            let maxRecordingSpeedInRadiants = sensorWidthInMeters * movementPerFrameInPixels / (Double(captureWidth) * exposureDuration)
            
            let maxRecordingSpeed = ballSphereRadius * Float(maxRecordingSpeedInRadiants)
            
            //print("exposure duration: \(exposureDuration), maxSpeed per second: \(maxRecordingSpeed), capturewidth: \(captureWidth)")
            
            let timeDiff = (newTime - time)
            let maxSpeed = Float(maxRecordingSpeed) * Float(timeDiff)
            
            let accelleration = (!recorder.isIdle() ? Float(maxRecordingSpeed / 3) : Float(maxRecordingSpeed)) / Float(9)
            
            let newHeading = GLKVector3Subtract(target, ball)
            
            let dist = GLKVector3Length(newHeading)
            var curSpeed = GLKVector3Length(ballSpeed)
            
            // We have to actually break.
            if sqrt(dist / accelleration) >= dist / curSpeed {
                curSpeed -= accelleration
            } else {
                curSpeed += accelleration
            }
            
            // Limit speed
            if curSpeed < 0 {
                curSpeed = 0
            }
            
            if curSpeed > maxSpeed {
                curSpeed = sign(curSpeed) * maxSpeed
            }
            
            if curSpeed > dist {
                curSpeed = dist
            }
            
            //newSpeed = GLKVector3Subtract(newSpeed, ballSpeed)
            if GLKVector3Length(newHeading) != 0 {
                ballSpeed = GLKVector3MultiplyScalar(GLKVector3Normalize(newHeading), curSpeed)
            } else {
                ballSpeed = newHeading
            }
            ballNode.position = SCNVector3FromGLKVector3(GLKVector3Add(ball, ballSpeed))
        }
        
        time = newTime
        
    }
    
    private func setupCamera() {
        authorizeCamera()
        
        //session.sessionPreset = AVCaptureSessionPresetHigh
        session.sessionPreset = AVCaptureSessionPreset1280x720
        //session.sessionPreset = AVCaptureSessionPresetMedium

        
        videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!) else {
            return
        }
        
        session.beginConfiguration()
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        }
        
        let videoDeviceOutput = AVCaptureVideoDataOutput()
        videoDeviceOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
        videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
        videoDeviceOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if session.canAddOutput(videoDeviceOutput) {
            session.addOutput(videoDeviceOutput)
        }
        
        let conn = videoDeviceOutput.connectionWithMediaType(AVMediaTypeVideo)
        conn.videoOrientation = AVCaptureVideoOrientation.Portrait
        
        session.commitConfiguration()
        
        try! videoDevice?.lockForConfiguration()
        
        
        var bestFormat: AVCaptureDeviceFormat?
        //var bestFrameRate: AVFrameRateRange?
        
        var maxFps: Double = 0
        
        for format in videoDevice!.formats.map({ $0 as! AVCaptureDeviceFormat }) {
            var ranges = format.videoSupportedFrameRateRanges as! [AVFrameRateRange]
            let frameRates = ranges[0]
            if frameRates.maxFrameRate >= maxFps && frameRates.maxFrameRate <= 30 {
                maxFps = frameRates.maxFrameRate
                bestFormat = format
                
            }
        }
        
        if videoDevice!.activeFormat.videoHDRSupported.boolValue {
            videoDevice!.automaticallyAdjustsVideoHDREnabled = false
            videoDevice!.videoHDREnabled = false
        }
        
        videoDevice!.exposureMode = .ContinuousAutoExposure
        videoDevice!.whiteBalanceMode = .ContinuousAutoWhiteBalance
        
        AVCaptureVideoStabilizationMode.Standard
        
        videoDevice!.activeVideoMinFrameDuration = CMTimeMake(1, 30)
        videoDevice!.activeVideoMaxFrameDuration = CMTimeMake(1, 30)
        
        videoDevice!.unlockForConfiguration()
        
        session.startRunning()
    }
    
    private func authorizeCamera() {
        var alreadyFailed = false
        let failAlert = {
            Async.main { [weak self] in
                if alreadyFailed {
                    return
                } else {
                    alreadyFailed = true
                }
                
                let alert = UIAlertController(title: "No access to camera", message: "Please enable permission to use the camera and photos.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Enable", style: .Default, handler: { _ in
                    UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
                }))
                self?.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { granted in
            if !granted {
                failAlert()
            }
        })
        
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .NotDetermined, .Restricted, .Denied: failAlert()
            default: ()
            }
        }
    }
    
    private func processSampleBuffer(sampleBuffer: CMSampleBufferRef ,exposureTime:Double) {
        
        if recorder.isFinished() {
            return; //Dirt return here. Recording is running on the main thread.
        }
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        

        if let pixelBuffer = pixelBuffer { //, motion = self.motionManager.deviceMotion {
            
            //let cmRotation = CMRotationToGLKMatrix4(motion.attitude.rotationMatrix)
            CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
            
            var buf = ImageBuffer()
            buf.data = CVPixelBufferGetBaseAddress(pixelBuffer)
            buf.width = UInt32(CVPixelBufferGetWidth(pixelBuffer))
            buf.height = UInt32(CVPixelBufferGetHeight(pixelBuffer))
            
            captureWidth = Int(buf.width)
            
            recorder.setIdle(!self.viewModel.isRecording.value)
            var cmRotation : GLKMatrix4
            
            if Defaults[.SessionMotor] {
                
                //Motor Fixed 1ring
                let mediaTime = CACurrentMediaTime()
                print("mediaTime \(mediaTime)")
                let timeDiff = mediaTime - lastElapsedTime
                print("timeDiff \(timeDiff)")
                
                print("lastElapsedTime \(lastElapsedTime)")
                
                // static degree per 0.0001ms = 0.000475 for 75.789 s
                // static degree per 0.0001ms = 0.002 for 18.0 s
                // static degree per 0.0001ms = 0.00175 for 20.571 s
                
                
                //let degreeIncr = (timeDiff / 0.0001 ) * 0.00175
                //let degreeIncr = (timeDiff / 0.0001 ) * 0.000475
                //var degreeIncr = (timeDiff / 0.0001 ) * 0.000850013
                let degreeIncr = ((timeDiff / 0.0001) * DegreeIncrPerMicro )//<- our version
                //var degreeIncr = (timeDiff / 0.0001) * 0.001650846
                //var degreeIncr = (timeDiff / 0.0001) * 0.001479411
                
                print("degreeIncr \(degreeIncr) M_PI \(-M_PI_2)")
                
                if viewModel.isRecording.value {
                    currentDegree -= Float(degreeIncr)
                    //currentDegree += Float(degreeIncr)
                }
                print("currentDegree \(currentDegree)")
                
                
                lastElapsedTime = mediaTime
                
                let rotation = GLKMatrix4MakeYRotation(GLKMathDegreesToRadians(Float(currentDegree)))
                
                print("rotation \(rotation)")
                
                // var xrotation = GLKMatrix4MakeXRotation(GLKMathDegreesToRadians(Float(30.0)))
                
                let currentRotation = GLKMatrix4Multiply(baseMatrix, rotation)
                print("currentRotation \(currentRotation)")
                // currentRotation = GLKMatrix4Multiply(currentRotation, rotation)
                
                //var currentRad = currentDegree  * Float(M_PI / 180.0)
                //print("currentRad  \(currentRad)" )
                //var currentRotation = GLKMatrix4Rotate(baseMatrix, 1.0, 0.0, currentRad, 0.0)
                
                print("currentDegree \(currentDegree) CACurrentMediaTime \(mediaTime) ")
                
                currentPhi = GLKMathDegreesToRadians(Float(currentDegree))
                print("currentPhi \(currentPhi)")
                
                cmRotation = self.rotationSource.getRotationMatrixMotor(currentPhi, thetaValue: currentTheta)
                print("Matrix: [\(cmRotation.m00), \(cmRotation.m01), \(cmRotation.m02), \(cmRotation.m03)")
                print("______: [\(cmRotation.m10), \(cmRotation.m11), \(cmRotation.m12), \(cmRotation.m13)")
                print("______: [\(cmRotation.m20), \(cmRotation.m21), \(cmRotation.m22), \(cmRotation.m23)")
                print("______: [\(cmRotation.m30), \(cmRotation.m31), \(cmRotation.m32), \(cmRotation.m33)")
                
                if bData.dataHasCome.value  {
                    viewModel.isRecording.value = true
                    
                }
                
                print("currentPhi <  \(Float((-2.0 * M_PI) - 0.01))")
                if (currentPhi < Float((-2.0 * M_PI) - 0.01)) {
                    viewModel.isRecording.value = false //<-
                    
                    /*print("ito?>>>>>",bData.ydirection)
                     if self.bData.ydirection == "fffffe0b"{
                     print(">>>>why?")
                     viewModel.isRecording.value = true
                     
                     }*/
                    
                    if(currentTheta == 0) {
                        currentTheta = Float(-0.718)
                    } else if(currentTheta < 0) {
                        currentTheta = Float(0.718)
                    } else if(currentTheta > 0) {
                        currentTheta = Float(0)
                    }
                    currentDegree = 0
                }
                print("currentTheta \(currentTheta)")

                
                
            } else {
            
            
                cmRotation = motionManager.getRotationMatrix()
                print("cmRotation \(cmRotation)")
              
        
                
            }
              recorder.push(cmRotation, buf, lastExposureInfo, lastAwbGains)
            let errorVec = recorder.getAngularDistanceToBall()
            // let r = recorder.getCurrentRotation()
            // let exposureHintC = recorder.getExposureHint()
            
            
            Async.main {
                if self.isViewLoaded() {
                    // This is safe, since the main thread also disposes the stitcher.
                    if self.recorder.isDisposed() || self.recorder.isFinished() {
                        return
                    }
                    
                    // Progress bar
                    self.viewModel.progress.value = Float(self.recorder.getRecordedImagesCount()) / Float(self.recorder.getImagesToRecordCount())
                    
                    // Normal towards ring
                    self.viewModel.tiltAngle.value = Float(errorVec.z)
                    
                    // Helpers for bearing and distance. Relative to ball.
                    let unit = GLKVector3Make(0, 0, -1)
                    let ballHeading = GLKVector3Normalize(SCNVector3ToGLKVector3(self.ballNode.position))
                    let currentHeading = GLKVector3Normalize(GLKMatrix4MultiplyVector3(cmRotation, unit))
                    //print("Diff: \(diff.x), \(diff.y), \(diff.z)")
                    
                    // Use 3D diff as dist
                    let diff = GLKVector3Subtract(ballHeading, currentHeading);
                    self.viewModel.distXY.value = GLKVector3Length(diff)
                    
                    // (Approximate) bearing betwenn ballHeading and currentHeading on Sphere
                    let angularBallHeading = carthesianToSpherical(ballHeading)
                    let angularCurrentHeading = carthesianToSpherical(currentHeading)
                    
                    // print("Angular: \(angularBallHeading.x), \(angularBallHeading.y), \(angularCurrentHeading.x), \(angularCurrentHeading.y)")
                    
                    let angularDiff = GLKVector2Make(asin(sin(angularBallHeading.s - angularCurrentHeading.s)),
                        asin(sin(angularBallHeading.t - angularCurrentHeading.t)))
                    
                    self.viewModel.headingToDot.value = atan2(angularDiff.x, angularDiff.y)
                }
                // TODO: Re-enable this code as soon as apple fixes
                // the memory leak in AVCaptureDevice.ISO and stuff.
                
//                               var exposureHint = exposureHintC;
//            
//                                if let videoDevice = self.videoDevice {
//                                    self.lastExposureInfo.iso = UInt32(videoDevice.ISO)
//                                    self.lastExposureInfo.exposureTime = videoDevice.exposureDuration.seconds
//                                    self.lastAwbGains = videoDevice.deviceWhiteBalanceGains
//                               }
//                
//                                if let videoDevice = self.videoDevice {
//                
//                                    self.lastExposureInfo.iso = UInt32(videoDevice.ISO)
//                                    self.lastExposureInfo.exposureTime = videoDevice.exposureDuration.seconds
//                                    self.lastAwbGains = videoDevice.deviceWhiteBalanceGains
//                
//                                    if exposureHint.iso != 0 {
//                
//                                        if exposureHint.iso > UInt32(videoDevice.activeFormat.maxISO) {
//                                            exposureHint.iso = UInt32(videoDevice.activeFormat.maxISO)
//                                        }
//                                        if exposureHint.iso < UInt32(videoDevice.activeFormat.minISO) {
//                                            exposureHint.iso = UInt32(videoDevice.activeFormat.minISO)
//                                        }
//                
//                                        print("Hint: \(exposureHint.iso), Max: \(videoDevice.activeFormat.maxISO)")
//                                        try! videoDevice.lockForConfiguration()
//                                        videoDevice.exposureMode = .Custom
//                                        videoDevice.whiteBalanceMode = .Locked
//                
//                                        videoDevice.setExposureModeCustomWithDuration(
//                                            CMTimeMakeWithSeconds(exposureHint.exposureTime, 10000),
//                                            ISO: Float(exposureHint.iso), completionHandler: nil)
//                
//                                        videoDevice.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(exposureHint.gains, completionHandler: nil)
//                
//                
//                                        videoDevice.unlockForConfiguration()
//                                    }
//                
//                                }
            }
            cameraNode.transform = SCNMatrix4FromGLKMatrix4(cmRotation)

            updateBallPosition(exposureTime)
            
            if recorder.hasStarted() {
                let currentKeyframe = recorder.lastKeyframe()
                
                if lastKeyframe == nil {
                    lastKeyframe = currentKeyframe
                }
                else if currentKeyframe.globalId != lastKeyframe?.globalId {
                    let recordedEdge = Edge(lastKeyframe!, currentKeyframe)
                    edges[recordedEdge]?.geometry!.firstMaterial!.diffuse.contents = UIColor(hex:0xFF5E00)
                    lastKeyframe = currentKeyframe
                }
            }
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
            
            
            //print("New CM Transform {\(cameraNode.transform.m11), \(cameraNode.transform.m12), \(cameraNode.transform.m13), \(cameraNode.transform.m14)} \n {\(cameraNode.transform.m21), \(cameraNode.transform.m22), \(cameraNode.transform.m23), \(cameraNode.transform.m24)} \n {\(cameraNode.transform.m31), \(cameraNode.transform.m32), \(cameraNode.transform.m33), \(cameraNode.transform.m34)} \n {\(cameraNode.transform.m41), \(cameraNode.transform.m42), \(cameraNode.transform.m43), \(cameraNode.transform.m44)}");
            
            if recorder.isFinished() {
                // needed since processSampleBuffer doesn't run on UI thread
                Async.main {
                    self.finish()
                }
            }
            
            //We always need debug data, even when not recording - the aligner is not paused when idle.
            //debugHelper?.push(pixelBuffer, intrinsics: map(self.intrinsics.m) { Double($0) }, extrinsics: CMRotationToDoubleArray(motion.attitude.rotationMatrix), frameCount: frameCount)
        }
    }
    
    private func stopSession() {
        
        if let videoDevice = self.videoDevice {
            try! videoDevice.lockForConfiguration()
            videoDevice.focusMode = .ContinuousAutoFocus
            videoDevice.exposureMode = .ContinuousAutoExposure
            videoDevice.whiteBalanceMode = .ContinuousAutoWhiteBalance
            videoDevice.unlockForConfiguration()
        }
        
        session.stopRunning()
        videoDevice = nil
        
//        for child in scene.rootNode.childNodes {
//            child.removeFromParentNode()
//        }
        
        scene.rootNode.childNodes.forEach {
            $0.removeFromParentNode()
        }
        
        scnView.removeFromSuperview()
    }
    
    func finish() {
        
        Mixpanel.sharedInstance().track("Action.Camera.FinishRecording")
        
        stopSession()
        
        let recorder_ = recorder
        
        let recorderCleanup = SignalProducer<UIImage, NoError> { sink, disposable in
            
            if recorder_.previewAvailable() {
                let previewData = recorder_.getPreviewImage()
                autoreleasepool {
                    sink.sendNext(UIImage(CGImage: ImageBufferToCGImage(previewData)))
                }
                Recorder.freeImageBuffer(previewData)
            }
            recorder_.finish()
            
            sink.sendCompleted()
            
            // TODO - get images
            
            recorder_.dispose()
        }
        let createOptographViewController = SaveViewController(recorderCleanup: recorderCleanup)
        createOptographViewController.hidesBottomBarWhenPushed = true
        navigationController!.pushViewController(createOptographViewController, animated: false)
        navigationController!.viewControllers.removeAtIndex(1)
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        let metadataDict:NSDictionary = CMCopyDictionaryOfAttachments(nil, sampleBuffer, kCMAttachmentMode_ShouldPropagate)!
        
        var exifData = NSDictionary()
        exifData = metadataDict.objectForKey(kCGImagePropertyExifDictionary) as! NSDictionary
        
        let exposureTimeValue = exifData.objectForKey(kCGImagePropertyExifExposureTime as String)!
        
        processSampleBuffer(sampleBuffer,exposureTime: exposureTimeValue.doubleValue)
        frameCount += 1
    }
}

// MARK: - SCNSceneRendererDelegate
extension CameraViewController: SCNSceneRendererDelegate {
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        //let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .ShortStyle, timeStyle: .LongStyle)
        
        //print("[\(timestamp)] Rendering");
        glLineWidth(lineWidth * screenScale)
    }
    
}

private struct Edge: Hashable {
    let one: SelectionPoint
    let two: SelectionPoint
    
    var hashValue: Int {
        return one.globalId.hashValue ^ two.globalId.hashValue
    }
    
    init(_ one: SelectionPoint, _ two: SelectionPoint) {
        self.one = one
        self.two = two
    }
}

private func ==(lhs: Edge, rhs: Edge) -> Bool {
    return lhs.one.globalId == rhs.one.globalId && lhs.two.globalId == rhs.two.globalId
}

private class DashedCircleView: UIView {
    
    var isActive = false {
        didSet {
            border.strokeColor = isActive ? UIColor(hex:0xFF5E00).CGColor : UIColor.whiteColor().CGColor
        }
    }
    
    var isDashed = true {
        didSet {
            border.lineDashPattern = isDashed ? [19, 8] : nil
        }
    }
    
    private let border = CAShapeLayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        border.fillColor = nil
        border.lineWidth = 4
        border.opacity = 0.8
        
        layer.addSublayer(border)
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func layoutSubviews() {
        super.layoutSubviews()
        
        border.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: layer.cornerRadius).CGPath
        border.frame = bounds
    }
    
}

private class CameraProgressView: UIView {
    
    var progress: Float = 0 {
        didSet {
            layoutSubviews()
        }
    }
    var isActive = false {
        didSet {
            foregroundLine.backgroundColor = isActive ? UIColor(hex:0xFF5E00).CGColor : UIColor.whiteColor().CGColor
            trackingPoint.backgroundColor = isActive ? UIColor(hex:0xFF5E00).CGColor : UIColor.whiteColor().CGColor
        }
    }
    
    private let firstBackgroundLine = CALayer()
    private let endPoint = CALayer()
    private let foregroundLine = CALayer()
    private let trackingPoint = CALayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        firstBackgroundLine.backgroundColor = UIColor.whiteColor().CGColor
        layer.addSublayer(firstBackgroundLine)
        
        endPoint.backgroundColor = UIColor.whiteColor().CGColor
        endPoint.cornerRadius = 3.5
        layer.addSublayer(endPoint)
        
        foregroundLine.cornerRadius = 1
        layer.addSublayer(foregroundLine)
        
        trackingPoint.cornerRadius = 7
        layer.addSublayer(trackingPoint)
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = bounds.width - 12
        let originX = bounds.origin.x + 6
        let originY = bounds.origin.y + 6
        
        firstBackgroundLine.frame = CGRect(x: originX, y: originY - 0.6, width: width, height: 1.2)
        endPoint.frame = CGRect(x: width + 3.5, y: originY - 3.5, width: 7, height: 7)
        foregroundLine.frame = CGRect(x: originX, y: originY - 1, width: width * CGFloat(progress), height: 2)
        trackingPoint.frame = CGRect(x: originX + width * CGFloat(progress) - 6, y: originY - 6, width: 12, height: 12)
    }
}

private class TiltView: UIView {
    var angle: Float = 0 {
        didSet {
            updatePaths()
        }
    }
    
    var distXY: Float = 0 {
        didSet {
            updatePaths()
        }
    }
    
    
    var innerRadius: Float = 0 {
        didSet {
            updatePaths()
        }
    }
    
    private let diagonalLine = CAShapeLayer()
    private let verticalLine = CAShapeLayer()
    private let ringSegment = CAShapeLayer()
    private let circleSegment = CAShapeLayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        diagonalLine.strokeColor = UIColor.whiteColor().CGColor
        diagonalLine.fillColor = UIColor.clearColor().CGColor
        diagonalLine.lineWidth = 2
        layer.addSublayer(diagonalLine)
        
        verticalLine.strokeColor = UIColor(hex:0xFF5E00).CGColor
        verticalLine.fillColor = UIColor.clearColor().CGColor
        verticalLine.lineWidth = 2
        layer.addSublayer(verticalLine)
        
        ringSegment.strokeColor = UIColor(hex:0xFF5E00).CGColor
        ringSegment.fillColor = UIColor(hex:0xFF5E00).CGColor
        ringSegment.lineWidth = 2
        layer.addSublayer(ringSegment)
        
        circleSegment.strokeColor = UIColor.clearColor().CGColor
        circleSegment.fillColor = UIColor(hex:0xFF5E00).hatched2.CGColor
        layer.addSublayer(circleSegment)
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updatePaths() {
        let angle = CGFloat(self.angle)
        let swap = {(inout a: CGFloat, inout b: CGFloat) in
            if angle < 0 {
                let tmp = a
                a = b
                b = tmp
            }
        }
        
        let cx = bounds.width / 2
        let cy = bounds.height / 2
        
        let diagonalPath = UIBezierPath()
        diagonalPath.moveToPoint(CGPoint(x: cx - tan(angle) * cy, y: 0))
        diagonalPath.addLineToPoint(CGPoint(x: cx + tan(angle) * cy, y: bounds.height))
        diagonalLine.path = diagonalPath.CGPath
        
        let verticalPath = UIBezierPath()
        let verticalLineHeight = (cy - CGFloat(innerRadius)) * 3 / 5
        let radius = verticalLineHeight + CGFloat(innerRadius)
        verticalPath.moveToPoint(CGPoint(x: cx, y: cy - radius))
        verticalPath.addLineToPoint(CGPoint(x: cx, y: cy - CGFloat(innerRadius)))
        verticalLine.path = verticalPath.CGPath
        
        let ringSegmentPath = UIBezierPath()
        let offsetAngle = min(abs(angle) * 2, CGFloat(Float(M_PI * 0.05))) * (angle > 0 ? 1 : -1)
        var offsetStartAngle = CGFloat(-M_PI_2) + offsetAngle
        var offsetEndAngle = CGFloat(-M_PI_2) - angle - offsetAngle
        swap(&offsetStartAngle, &offsetEndAngle)
        ringSegmentPath.addArcWithCenter(CGPoint(x: cx, y: cy), radius: radius, startAngle: offsetStartAngle, endAngle: offsetEndAngle, clockwise: false)
        ringSegment.path = ringSegmentPath.CGPath
        
        let circleSegmentPath = UIBezierPath()
        let startAngle = CGFloat(-M_PI_2)
        let endAngle = CGFloat(-M_PI_2) - angle
        circleSegmentPath.moveToPoint(CGPoint(x: cx, y: cy - CGFloat(innerRadius)))
        circleSegmentPath.addArcWithCenter(CGPoint(x: cx, y: cy), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: angle < 0)
        circleSegmentPath.addLineToPoint(CGPoint(x: cx + CGFloat(innerRadius) * cos(endAngle), y: cy + CGFloat(innerRadius) * sin(endAngle)))
        circleSegmentPath.addArcWithCenter(CGPoint(x: cx, y: cy), radius: CGFloat(innerRadius), startAngle: endAngle, endAngle: startAngle, clockwise: angle > 0)
        circleSegment.path = circleSegmentPath.CGPath
        
        // Update transparency
        let visibleLimit = Float(M_PI / 90)
        let criticalLimit = Float(M_PI / 70)
        let distLimit = Float(M_PI / 30)
        if abs(self.angle) < visibleLimit {
            alpha = 0
        } else {
            alpha = min(0.8, CGFloat(0.8 * (1 - (criticalLimit - visibleLimit) / (abs(self.angle) - visibleLimit))))
            alpha = min(alpha, CGFloat((distLimit - self.distXY) / distLimit + 1))
            alpha = max(alpha, 0)
        }
    }
    
    private override func layoutSubviews() {
        super.layoutSubviews()
        
        updatePaths()
        
        diagonalLine.frame = bounds
        verticalLine.frame = bounds
        ringSegment.frame = bounds
        circleSegment.frame = bounds
    }
    
}
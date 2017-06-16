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
import ReactiveSwift
import Result
import Alamofire
import SceneKit
import Async
import Mixpanel
import SwiftyUserDefaults
import Photos
import CoreBluetooth

class CameraViewController: UIViewController ,CBPeripheralDelegate{
    
    fileprivate let viewModel = CameraViewModel()
    var motionManager: RotationMatrixSource!

    // camera
    fileprivate let session = AVCaptureSession()
    fileprivate let sessionQueue: DispatchQueue
    fileprivate var videoDevice : AVCaptureDevice?
    
    fileprivate var lastExposureInfo = ExposureInfo()
    fileprivate var lastAwbGains = AVCaptureWhiteBalanceGains()
    fileprivate var exposureDuration:Double = 1
    fileprivate var captureWidth = Int(1)
    
    fileprivate let sensorWidthInMeters = Double(0.004)
    fileprivate let estimatedArmLengthInMeters = Double(0.50)
    
    // stitcher pointer and variables
    fileprivate var recorder: Recorder!
    fileprivate var frameCount = 0
    fileprivate var debugCount = 0
    fileprivate var previewImageCount = 0
    fileprivate let intrinsics = CameraIntrinsics
    fileprivate var lastKeyframe: SelectionPoint?
    
    // lines
    fileprivate var edges: [Edge: SCNNode] = [:]
    fileprivate let screenScale : Float
    fileprivate let lineWidth = Float(3)
    var points = [SelectionPoint]()
    
    // subviews
    fileprivate let tiltView = TiltView()
    fileprivate let progressView = CameraProgressView()
    fileprivate let instructionView = UILabel()
    fileprivate let circleView = DashedCircleView()
    fileprivate let arrowView = UILabel()
    
    // sphere
    fileprivate let cameraNode = SCNNode()
    fileprivate var scnView : SCNView!
    fileprivate let scene = SCNScene()

    // motor
    var motorControl: MotorControl!
    let useMotor = Defaults[.SessionMotor]
    var verticalTimer: Timer!

    // ball
    fileprivate let ballNode = SCNNode()
    fileprivate var ballSpeed = GLKVector3Make(0, 0, 0)
    fileprivate let baseMatrix = GLKMatrix4Make(1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1 , 0.0, 0.0, -1.0, 0.00, 0.0, 0.0, 0.0, 0.0, 1.0)
    
    fileprivate var tapCameraButtonCallback: (() -> ())?
    fileprivate var lastElapsedTime = CACurrentMediaTime()
    fileprivate var currentTheta = Float(0.0)
    fileprivate var currentPhi = Float(0.0)
    
    fileprivate let cancelButton = UIButton()
    
    fileprivate var finishCommand: MotorCommand?
    
    required init() {
        sessionQueue = DispatchQueue(label: "cameraQueue", attributes: [])
        screenScale = Float(UIScreen.main.scale)
        
        if Defaults[.SessionDebuggingEnabled] {
            Recorder.enableDebug(CameraDebugService().path)
        }
        
        super.init(nibName: nil, bundle: nil)
        
        if !useMotor {
            motionManager = CoreMotionRotationSource()
        } else {
       //     verticalTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(Float(MotorControl.motorStepsY) * (45 / 360) / 1000), repeats: false, block: {_ in
       //         self.tabController!.cameraButton.isHidden = false
       //     })
        }
        
        tapCameraButtonCallback = { [weak self] in
            let confirmAlert = UIAlertController(title: "Hold the camera button", message: "In order to record please keep the camera button pressed", preferredStyle: .alert)
            confirmAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self?.present(confirmAlert, animated: true, completion: nil)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if !useMotor {
            (motionManager as! CoreMotionRotationSource).stop()
        }
        print("de init cameraviewcontroller")

        //We do that in our signal as soon as everything's finished
        //recorder.dispose()
        
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: view.bounds, options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.openGLES2.rawValue])
        } else {
            scnView = SCNView(frame: view.bounds)
        }
        
        // layer for preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.frame = view.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        viewModel.tiltAngle.producer.startWithValues { [weak self] val in self?.tiltView.angle = val }
        viewModel.distXY.producer.startWithValues { [weak self] val in self?.tiltView.distXY = val }
        tiltView.innerRadius = 35
        view.addSubview(tiltView)
        
        viewModel.progress.producer.startWithValues { [weak self] val in self?.progressView.progress = val }
        viewModel.isRecording.producer.startWithValues { [weak self] val in self?.progressView.isActive = val}
        view.addSubview(progressView)
        
        instructionView.font = UIFont.robotoOfSize(22, withType: .Medium)
        instructionView.numberOfLines = 0
        instructionView.textColor = .white
        instructionView.textAlignment = .center
        instructionView.rac_text <~ viewModel.instruction
        view.addSubview(instructionView)
        
        circleView.layer.cornerRadius = 35
        viewModel.isRecording.producer.startWithValues { [weak self] val in self?.circleView.isDashed = !val }
        viewModel.isCentered.producer.startWithValues { [weak self] val in self?.circleView.isActive = val }
        view.addSubview(circleView)
        
        // TODO: Re-enable Icomoon
        //arrowView.text = String.iconWithName(.Next)
        arrowView.textColor = UIColor(hex:0xFF5E00)
        arrowView.textAlignment = .center
        //arrowView.font = UIFont.iconOfSize(40)
        arrowView.rac_alpha <~ viewModel.distXY.producer.map { distXY in
            let distLimit = Float(M_PI / 30)
            return 1 - max(CGFloat((distLimit - distXY) / distLimit + 1), 0)
        }
        viewModel.headingToDot.producer
            .map { CGAffineTransform(rotationAngle: CGFloat($0) + CGFloat(M_PI_2)) }
            .startWithValues { [weak self] transform in self?.arrowView.transform = transform }
        view.addSubview(arrowView)
        
        view.setNeedsUpdateConstraints()
        
        cancelButton.addTarget(self, action: #selector(CameraViewController.cancelRecording), for: .touchUpInside)
        cancelButton.setImage(UIImage(named: "camera_back_button"), for: UIControlState())
        scnView.addSubview(cancelButton)
        cancelButton.anchorInCorner(.topLeft, xPad: 0, yPad: 15, width: 40, height: 40)
    }
    
    func touchEndCameraButton() {
        tapCameraButtonCallback = nil
    }
    
    func cancelRecording() {
        Mixpanel.sharedInstance()?.track("Action.Camera.CancelRecording")
//        verticalTimer.invalidate()
        tabController!.cameraButton.isHidden = false

        viewModel.isRecording.value = false
        tapCameraButtonCallback = nil
        
        stopSession()
        
        recorder.cancel()
        recorder.dispose()
        
        if StitchingService.hasUnstitchedRecordings() {
            StitchingService.removeUnstitchedRecordings()
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    fileprivate func setFocusMode(_ mode: AVCaptureFocusMode) {
        
        try! videoDevice!.lockForConfiguration()
        videoDevice!.focusMode = mode
        videoDevice!.unlockForConfiguration()
    }
    
    fileprivate func setExposureMode(_ mode: AVCaptureExposureMode) {
        try! videoDevice!.lockForConfiguration()
        
        if mode == AVCaptureExposureMode.custom {
            exposureDuration = videoDevice!.exposureDuration.seconds
            var iso = videoDevice!.iso
            if(iso > videoDevice!.activeFormat.maxISO) {
                iso = videoDevice!.activeFormat.maxISO
            }
            videoDevice?.setExposureModeCustomWithDuration(videoDevice!.exposureDuration, iso: iso, completionHandler: nil)
            videoDevice?.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(videoDevice!.deviceWhiteBalanceGains, completionHandler: { $0 })
        } else {
            videoDevice!.exposureMode = mode
        }
        videoDevice!.unlockForConfiguration()
    }
    
    fileprivate func setWhitebalanceMode(_ mode: AVCaptureWhiteBalanceMode) {
        try! videoDevice!.lockForConfiguration()
        videoDevice!.whiteBalanceMode = mode
        videoDevice!.unlockForConfiguration()
    }
    
    
    fileprivate func setupSelectionPoints() {
        let rawPoints = recorder.getSelectionPoints()!
        
        while rawPoints.hasMore() {
            let point = rawPoints.next()
            points.append(point!)
        }
        
        var points2 = points;
        points2.remove(at: 0);
        
        var i = 0
        
        for (a, b) in zip(points, points2) {
            if a.ringId == b.ringId {
                let edge = Edge(a, b)
                
                let vec = GLKVector3Make(0, 0, -1)
                let posA = GLKMatrix4MultiplyVector3(a.extrinsics, vec)
                let posB = GLKMatrix4MultiplyVector3(b.extrinsics, vec)
                
                print("\(posA.x) \(posA.y) \(posA.z)")
                print("\(posB.x) \(posB.y) \(posB.z)")
                
                let edgeNode = createLineNode(posA, posB: posB)
                
                // This code makes movement visible (half of the lines will be colored)
//                if i % 2 > 0 {
//                    edgeNode.geometry!.firstMaterial!.diffuse.contents = UIColor.black
//                }

                edges[edge] = edgeNode
                
                scene.rootNode.addChildNode(edgeNode)
                
                i += 1;
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        switch Defaults[.SessionUseMultiRing] {
        case true:
            self.recorder = Recorder(.Truncated)
        case false:
            self.recorder = Recorder(.Center)
        }
        
        if !useMotor {
            self.tabController!.cameraButton.isHidden = false
        }
        
        setupScene()
        setupBall()
        setupSelectionPoints()
        setupCamera()
        
        // Locks the focus as soon as the user starts recording.
        // We do this to avoid re-focusing during recording, which breaks the Optograph
        
        viewModel.isRecording.producer
            .map { $0 ? .locked : .continuousAutoFocus }
            .startWithValues { [unowned self] val in self.setFocusMode(val) }
        
        viewModel.isRecording.producer
            .filter { $0 }
            .take(first: 1)
            .startWithValues { [unowned self] val in
                self.setExposureMode(.custom)
                self.setWhitebalanceMode(.locked)
        }
        
        updateTabs()
        
        tabController!.delegate = self
        
        Mixpanel.sharedInstance()?.timeEvent("View.Camera")
        
        viewModel.isRecording.producer.filter(identity).take(first: 1).startWithValues { _ in
            Mixpanel.sharedInstance()?.track("Action.Camera.StartRecording")
        }
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        
        
        frameCount = 0
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        if !useMotor {
           (motionManager as! CoreMotionRotationSource).start()
        } else {
            tabController!.cameraButton.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: {
                self.onTapCameraButton()
            })
        }

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Mixpanel.sharedInstance()?.track("View.Camera")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabController!.cameraButton.isHidden = false
        
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.none)
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func updateViewConstraints() {
        view.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
        
        tiltView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero)
        
        progressView.autoPinEdge(.top, to: .top, of: view, withOffset: 28)
        progressView.autoMatch(.width, to: .width, of: view, withOffset: -80)
        progressView.autoAlignAxis(.vertical, toSameAxisOf: view)
        
        instructionView.autoAlignAxis(.horizontal, toSameAxisOf: view, withMultiplier: 0.5)
        instructionView.autoAlignAxis(.vertical, toSameAxisOf: view)
        
        arrowView.autoAlignAxis(.horizontal, toSameAxisOf: view)
        arrowView.autoAlignAxis(.vertical, toSameAxisOf: view)
        arrowView.autoSetDimensions(to: CGSize(width: 70, height: 70))
        
        circleView.autoAlignAxis(.horizontal, toSameAxisOf: view)
        circleView.autoAlignAxis(.vertical, toSameAxisOf: view)
        circleView.autoSetDimensions(to: CGSize(width: 70, height: 70))
        
        super.updateViewConstraints()
    }
    
    fileprivate func setupScene() {
        let camera = SCNCamera()
        let fov = 45 as Double
        camera.zNear = 0.01
        camera.zFar = 10000
        camera.xFov = fov
        camera.yFov = fov * Double(view.bounds.width / 2 / view.bounds.height)
        
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        scene.rootNode.addChildNode(cameraNode)
        
        scnView.backgroundColor = UIColor.clear
        scnView.scene = scene
        scnView.isPlaying = true
        scnView.delegate = self
        
        view.addSubview(scnView)
    }
    
    fileprivate func createLineNode(_ posA: GLKVector3, posB: GLKVector3) -> SCNNode {
        
        let positions: [Float32] = [posA.x, posA.y, posA.z, posB.x, posB.y, posB.z]
        let positionData = NSData(bytes: positions, length: MemoryLayout<Float32>.size * positions.count)
        let indices: [Int32] = [0, 1]
        let indexData = NSData(bytes: indices, length: MemoryLayout<Int32>.size * indices.count)
        
        
        let source = SCNGeometrySource(data: positionData as Data!, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: indices.count, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float32>.size, dataOffset: 0, dataStride: MemoryLayout<Float32>.size * 3)
        let element = SCNGeometryElement(data: indexData as Data!, primitiveType: SCNGeometryPrimitiveType.line, primitiveCount: indices.count, bytesPerIndex: MemoryLayout<Int32>.size)
        
        let line = SCNGeometry(sources: [source], elements: [element])
        let node = SCNNode(geometry: line)
        //node.position = SCNVector3(x: posA.x, y: posA.y, z: posA.z)
        line.firstMaterial?.diffuse.contents = UIColor.white
        
        return node
    }
    
    fileprivate func setupBall() {
        
        let ballGeometry = SCNSphere(radius: CGFloat(0.04))
        
        ballNode.geometry = ballGeometry
        ballNode.geometry?.firstMaterial?.diffuse.contents = UIColor(hex:0xFF5E00)
        
        scene.rootNode.addChildNode(ballNode)
    }
    
    fileprivate var time = Double(-1)
    
    fileprivate func updateBallPosition(_ expTime:Double) {
        
        // Quick hack to limit expo duration in calculations, due to unexpected results of CACurrentMediaTime
        
        let exposureDuration = max(self.exposureDuration, 0.006)
        //let exposureDuration = max(self.exposureDuration, expTime)
        
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
    
    fileprivate func setupCamera() {
        authorizeCamera()
        
        session.sessionPreset = AVCaptureSessionPresetHigh

        videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!) else {
            return
        }
        
        session.beginConfiguration()
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        }
        
        let videoDeviceOutput = AVCaptureVideoDataOutput()
        
        videoDeviceOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)
        ]
        videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
        videoDeviceOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if session.canAddOutput(videoDeviceOutput) {
            session.addOutput(videoDeviceOutput)
        }
        
        let conn = videoDeviceOutput.connection(withMediaType: AVMediaTypeVideo)!
        conn.videoOrientation = AVCaptureVideoOrientation.portrait
        
        session.commitConfiguration()
        
        try! videoDevice?.lockForConfiguration()
        
        var bestFormat: AVCaptureDeviceFormat?
        var bestFrameRate: AVFrameRateRange?
      
        for format in videoDevice!.formats.map({ $0 as! AVCaptureDeviceFormat }) {
            let dim = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if dim.height == 720 && dim.width == 1280 {
                for rate in format.videoSupportedFrameRateRanges.map({ $0 as! AVFrameRateRange }) {
                    if bestFormat == nil || bestFrameRate!.minFrameDuration > rate.minFrameDuration {
                        bestFormat = format
                        bestFrameRate = rate
                    }
                }

            }
            // Print formats, for debugging. 
            // for rate in format.videoSupportedFrameRateRanges.map({ $0 as! AVFrameRateRange }) {
            //     print(format)
            //    print(rate)
            // }
        }
        
        print(bestFormat)
        print(bestFrameRate)
        
        videoDevice?.activeFormat = bestFormat!
        
        if videoDevice!.activeFormat.isVideoHDRSupported {
            videoDevice!.automaticallyAdjustsVideoHDREnabled = false
            videoDevice!.isVideoHDREnabled = false
        }
        
        videoDevice!.exposureMode = .continuousAutoExposure
        videoDevice!.whiteBalanceMode = .continuousAutoWhiteBalance
        
        videoDevice!.activeVideoMinFrameDuration = bestFrameRate!.minFrameDuration
        videoDevice!.activeVideoMaxFrameDuration = bestFrameRate!.minFrameDuration
        
        videoDevice!.unlockForConfiguration()
        
        session.startRunning()
    }
    
    fileprivate func authorizeCamera() {
        var alreadyFailed = false
        let failAlert = {
            Async.main { [weak self] in
                if alreadyFailed {
                    return
                } else {
                    alreadyFailed = true
                }
                
                let alert = UIAlertController(title: "No access to camera", message: "Please enable permission to use the camera and photos.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Enable", style: .default, handler: { _ in
                    UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
                }))
                self?.present(alert, animated: true, completion: nil)
            }
        }
        
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { granted in
            if !granted {
                failAlert()
            }
        })
        
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .notDetermined, .restricted, .denied: failAlert()
            default: ()
            }
        }
    }
    
    fileprivate func processSampleBuffer(_ sampleBuffer: CMSampleBuffer ,exposureTime:Double) {
        
        if recorder.isFinished() {
            return; //Dirt return here. Recording is running on the main thread.
        }
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        

        if let pixelBuffer = pixelBuffer { //, motion = self.motionManager.deviceMotion {
            
            //let cmRotation = CMRotationToGLKMatrix4(motion.attitude.rotationMatrix)
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            
            var buf = ImageBuffer()
            buf.data = CVPixelBufferGetBaseAddress(pixelBuffer)
            buf.width = UInt32(CVPixelBufferGetWidth(pixelBuffer))
            buf.height = UInt32(CVPixelBufferGetHeight(pixelBuffer))
            
            captureWidth = Int(buf.width)
            
            recorder.setIdle(!self.viewModel.isRecording.value)
            var cmRotation : GLKMatrix4

            cmRotation = self.motionManager.getRotationMatrix()
            
            recorder.push(cmRotation, buf, lastExposureInfo, lastAwbGains)
            let errorVec = recorder.getAngularDistanceToBall()
            // let r = recorder.getCurrentRotation()
            // let exposureHintC = recorder.getExposureHint()
            
            
            Async.main {
                if self.isViewLoaded {
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

            }
            cameraNode.transform = SCNMatrix4FromGLKMatrix4(cmRotation)

            updateBallPosition(exposureTime)
            
            if recorder.hasStarted() {
                let currentKeyframe = recorder.lastKeyframe()!
                
                if lastKeyframe == nil {
                    lastKeyframe = currentKeyframe
                }
                else if currentKeyframe.globalId != lastKeyframe?.globalId {
                    let recordedEdge = Edge(lastKeyframe!, currentKeyframe)
                    edges[recordedEdge]?.geometry!.firstMaterial!.diffuse.contents = UIColor(hex:0xFF5E00)
                    lastKeyframe = currentKeyframe
                }
            }
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            
            if recorder.isFinished() {
                // needed since processSampleBuffer doesn't run on UI thread
                Async.main {
                    self.finish()
                }
            }
        }
    }
    
    fileprivate func stopSession() {
        
        if let videoDevice = self.videoDevice {
            try! videoDevice.lockForConfiguration()
            videoDevice.focusMode = .continuousAutoFocus
            videoDevice.exposureMode = .continuousAutoExposure
            videoDevice.whiteBalanceMode = .continuousAutoWhiteBalance
            videoDevice.unlockForConfiguration()
        }
        
        session.stopRunning()
        videoDevice = nil
        
        scene.rootNode.childNodes.forEach {
            $0.removeFromParentNode()
        }
        
        scnView.removeFromSuperview()
    }
    
    func finish() {
        
        Mixpanel.sharedInstance()?.track("Action.Camera.FinishRecording")
        
        if useMotor {
            motorControl.runScript(script: [finishCommand!])
        }
        
        stopSession()
        
        let recorder_ = recorder!
        
        let recorderCleanup = SignalProducer<UIImage, NoError> { sink, disposable in
            
            if recorder_.previewAvailable() {
                let previewData = recorder_.getPreviewImage()
                autoreleasepool {
                    sink.send(value: UIImage(cgImage: ImageBufferToCGImage(previewData)))
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
        navigationController!.viewControllers.remove(at: 1)
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
//        let metadataDict:NSDictionary = CMCopyDictionaryOfAttachments(nil, sampleBuffer, kCMAttachmentMode_ShouldPropagate)!
//        
//        var exifData = NSDictionary()
//        exifData = metadataDict.objectForKey(kCGImagePropertyExifDictionary) as! NSDictionary
//        
//        let exposureTimeValue = exifData.objectForKey(kCGImagePropertyExifExposureTime as String)!

        processSampleBuffer(sampleBuffer,exposureTime: 0.006)
        //processSampleBuffer(sampleBuffer,exposureTime: exposureTimeValue.doubleValue)
        frameCount += 1
    }
}

// MARK: - SCNSceneRendererDelegate
extension CameraViewController: SCNSceneRendererDelegate {
    
    func renderer(_ aRenderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
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
            border.strokeColor = isActive ? UIColor(hex:0xFF5E00).cgColor : UIColor.white.cgColor
        }
    }
    
    var isDashed = true {
        didSet {
            border.lineDashPattern = isDashed ? [19, 8] : nil
        }
    }
    
    fileprivate let border = CAShapeLayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        border.fillColor = nil
        border.lineWidth = 4
        border.opacity = 0.8
        
        layer.addSublayer(border)
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        
        border.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: layer.cornerRadius).cgPath
        border.frame = bounds
    }
    
}
    
extension CameraViewController: TabControllerDelegate {
        
    func onTouchEndCameraButton() {
        tapCameraButtonCallback = nil
    }
        
    func onTapCameraButton() {
        tabController!.cameraButton.isHidden = true
        viewModel.isRecording.value = true
        if useMotor {
            let v = calculatePoints()
            var thetaValues = [Float]()
            
            // Hard coded re-ordering. Please look away.
            if(v.count == 3) {
                thetaValues = [v[1], v[2], v[0]]
            } else if(v.count == 1) {
                thetaValues = [v[0]]
            } else {
                assert(false)
            }
            
            var sum = Float(0)
            
            for index in 1..<thetaValues.count {
                thetaValues[index] = thetaValues[index] - thetaValues[index - 1]
                sum = sum + thetaValues[index]
            }
            thetaValues[0] = 0
            
            // TODO: Make speed variable
            let script = thetaValues.flatMap { pos in
                return [
                    MotorCommand(
                        _dest: Point(x: 0, y: pos),
                        _speed: Point(x: 500, y: 1000)
                    ),
                    MotorCommand(
                        _dest: Point(x: Float(M_PI * 2), y: 0),
                        _speed: Point(x: 500, y: 1000)
                    )
                ]
            }
            
            finishCommand = MotorCommand(_dest: Point(x: 0, y: -sum), _speed: Point(x: 1000, y: 500))
            
            motorControl.runScript(script: script)
        }
    }

    func calculatePoints() -> [Float] {
        var result = [Float]()
        let vec = GLKVector3Make(0, 0, -1)
        for i in points {
            let posA = GLKMatrix4MultiplyVector3(i.extrinsics, vec)
            let angle = -asin(posA.z)
            
            if !result.contains(angle) {
                result.append(angle)
            }
        }
        return result
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
            foregroundLine.backgroundColor = isActive ? UIColor(hex:0xFF5E00).cgColor : UIColor.white.cgColor
            trackingPoint.backgroundColor = isActive ? UIColor(hex:0xFF5E00).cgColor : UIColor.white.cgColor
        }
    }
    
    fileprivate let firstBackgroundLine = CALayer()
    fileprivate let endPoint = CALayer()
    fileprivate let foregroundLine = CALayer()
    fileprivate let trackingPoint = CALayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        firstBackgroundLine.backgroundColor = UIColor.white.cgColor
        layer.addSublayer(firstBackgroundLine)
        
        endPoint.backgroundColor = UIColor.white.cgColor
        endPoint.cornerRadius = 3.5
        layer.addSublayer(endPoint)
        
        foregroundLine.cornerRadius = 1
        layer.addSublayer(foregroundLine)
        
        trackingPoint.cornerRadius = 7
        layer.addSublayer(trackingPoint)
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate override func layoutSubviews() {
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
    
    fileprivate let diagonalLine = CAShapeLayer()
    fileprivate let verticalLine = CAShapeLayer()
    fileprivate let ringSegment = CAShapeLayer()
    fileprivate let circleSegment = CAShapeLayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        diagonalLine.strokeColor = UIColor.white.cgColor
        diagonalLine.fillColor = UIColor.clear.cgColor
        diagonalLine.lineWidth = 2
        layer.addSublayer(diagonalLine)
        
        verticalLine.strokeColor = UIColor(hex:0xFF5E00).cgColor
        verticalLine.fillColor = UIColor.clear.cgColor
        verticalLine.lineWidth = 2
        layer.addSublayer(verticalLine)
        
        ringSegment.strokeColor = UIColor(hex:0xFF5E00).cgColor
        ringSegment.fillColor = UIColor(hex:0xFF5E00).cgColor
        ringSegment.lineWidth = 2
        layer.addSublayer(ringSegment)
        
        circleSegment.strokeColor = UIColor.clear.cgColor
        circleSegment.fillColor = UIColor(hex:0xFF5E00).hatched2.cgColor
        layer.addSublayer(circleSegment)
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func updatePaths() {
        let angle = CGFloat(self.angle)
        let swap = {(a: inout CGFloat, b: inout CGFloat) in
            if angle < 0 {
                let tmp = a
                a = b
                b = tmp
            }
        }
        
        let cx = bounds.width / 2
        let cy = bounds.height / 2
        
        let diagonalPath = UIBezierPath()
        diagonalPath.move(to: CGPoint(x: cx - tan(angle) * cy, y: 0))
        diagonalPath.addLine(to: CGPoint(x: cx + tan(angle) * cy, y: bounds.height))
        diagonalLine.path = diagonalPath.cgPath
        
        let verticalPath = UIBezierPath()
        let verticalLineHeight = (cy - CGFloat(innerRadius)) * 3 / 5
        let radius = verticalLineHeight + CGFloat(innerRadius)
        verticalPath.move(to: CGPoint(x: cx, y: cy - radius))
        verticalPath.addLine(to: CGPoint(x: cx, y: cy - CGFloat(innerRadius)))
        verticalLine.path = verticalPath.cgPath
        
        let ringSegmentPath = UIBezierPath()
        let offsetAngle = min(abs(angle) * 2, CGFloat(Float(M_PI * 0.05))) * (angle > 0 ? 1 : -1)
        var offsetStartAngle = CGFloat(-M_PI_2) + offsetAngle
        var offsetEndAngle = CGFloat(-M_PI_2) - angle - offsetAngle
        swap(&offsetStartAngle, &offsetEndAngle)
        ringSegmentPath.addArc(withCenter: CGPoint(x: cx, y: cy), radius: radius, startAngle: offsetStartAngle, endAngle: offsetEndAngle, clockwise: false)
        ringSegment.path = ringSegmentPath.cgPath
        
        let circleSegmentPath = UIBezierPath()
        let startAngle = CGFloat(-M_PI_2)
        let endAngle = CGFloat(-M_PI_2) - angle
        circleSegmentPath.move(to: CGPoint(x: cx, y: cy - CGFloat(innerRadius)))
        circleSegmentPath.addArc(withCenter: CGPoint(x: cx, y: cy), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: angle < 0)
        circleSegmentPath.addLine(to: CGPoint(x: cx + CGFloat(innerRadius) * cos(endAngle), y: cy + CGFloat(innerRadius) * sin(endAngle)))
        circleSegmentPath.addArc(withCenter: CGPoint(x: cx, y: cy), radius: CGFloat(innerRadius), startAngle: endAngle, endAngle: startAngle, clockwise: angle > 0)
        circleSegment.path = circleSegmentPath.cgPath
        
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
    
    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        
        updatePaths()
        
        diagonalLine.frame = bounds
        verticalLine.frame = bounds
        ringSegment.frame = bounds
        circleSegment.frame = bounds
    }
    
}

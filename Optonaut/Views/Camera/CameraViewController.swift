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
import Async
import Crashlytics

class CameraViewController: UIViewController {
    
    private let viewModel = CameraViewModel()
    
    private let motionManager = CMMotionManager()
    private var originalBrightness: CGFloat!
    
    // camera
    private let session = AVCaptureSession()
    private let sessionQueue: dispatch_queue_t = {
        let queue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL)
        let high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        dispatch_set_target_queue(queue, high)
        return queue
    }()
    
    // stitcher pointer and variables
    private var stitcher = IosPipeline()
    private var frameCount = 0
    private var previewImageCount = 0
    private let intrinsics = CameraIntrinsics
    private var debugHelper: CameraDebugService?
    private var edges = [Edge: SCNNode]()
    private var previewImage: CGImage?
    
    // subviews
    private let tiltView = TiltView()
    private let progressView = ProgressView()
    private let instructionView = UILabel()
    private let circleView = DashedCircleView()
    private let recordButtonView = UIButton()
    private let closeButtonView = UIButton()
    
    // sphere
    private let cameraNode = SCNNode()
    private let scnView = SCNView()
    private let scene = SCNScene()
    
    // ball
    private let ballNode = SCNNode()
    private var ballSpeed = GLKVector3Make(0, 0, 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Answers.logCustomEventWithName("Camera", customAttributes: ["State": "Recording"])
        
        // layer for preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        setupScene()
        setupBall()
        setupSelectionPoints()
        
        viewModel.tiltAngle.producer.startWithNext { self.tiltView.angle = $0 }
        viewModel.distXY.producer.startWithNext { self.tiltView.distXY = $0 }
        tiltView.innerRadius = 35
        view.addSubview(tiltView)
    
        viewModel.progress.producer.startWithNext { self.progressView.progress = $0 }
        viewModel.isRecording.producer.startWithNext { self.progressView.isActive = $0 }
        view.addSubview(progressView)
        
        instructionView.font = UIFont.robotoOfSize(22, withType: .Medium)
        instructionView.numberOfLines = 0
        instructionView.textColor = .whiteColor()
        instructionView.textAlignment = .Center
        instructionView.rac_text <~ viewModel.instruction
        view.addSubview(instructionView)
        
        circleView.layer.cornerRadius = 35
        viewModel.isRecording.producer.startWithNext { self.circleView.isDashed = !$0 }
        viewModel.isCentered.producer.startWithNext { self.circleView.isActive = $0 }
        view.addSubview(circleView)
        
        recordButtonView.rac_backgroundColor <~ viewModel.isRecording.producer.map { $0 ? UIColor.Accent.hatched2 : UIColor.whiteColor().hatched2 }
        recordButtonView.layer.cornerRadius = 35
        viewModel.isRecording <~ recordButtonView.rac_signalForControlEvents(.TouchDown).toSignalProducer()
            .map { _ in true }
            .flatMapError { _ in SignalProducer<Bool, NoError>.empty }
        viewModel.isRecording <~ recordButtonView.rac_signalForControlEvents([.TouchUpInside, .TouchUpOutside]).toSignalProducer()
            .map { _ in false }
            .flatMapError { _ in SignalProducer<Bool, NoError>.empty }
        view.addSubview(recordButtonView)
        
        closeButtonView.rac_hidden <~ viewModel.isRecording
        closeButtonView.setTitle("Cancel", forState: .Normal)
        closeButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        closeButtonView.titleLabel?.font = UIFont.robotoOfSize(16, withType: .Regular)
        closeButtonView.alpha = 0.8
        closeButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        view.addSubview(closeButtonView)
        
        if SessionService.sessionData!.debuggingEnabled {
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "finish"))
        }
        
        setupCamera()
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        view.setNeedsUpdateConstraints()
    }
    
    private func setupSelectionPoints() {
        
        let rawPoints = stitcher.GetSelectionPoints()
        var points = [SelectionPoint]()
        
        while rawPoints.HasMore() {
            let point = rawPoints.Next()
            points.append(point)
        }
        
        for a in points {
            for b in points {
                
                if stitcher.AreAdjacent(a, and: b) {
                    
                    let edge = Edge(a, b)
                    
                    let vec = GLKVector3Make(0, 0, -1)
                    let posA = GLKMatrix4MultiplyVector3(a.extrinsics, vec)
                    let posB = GLKMatrix4MultiplyVector3(b.extrinsics, vec)
                    
                    let edgeNode = createLineNode(posA, posB: posB)
                    
                    edges[edge] = edgeNode
                    
                    scene.rootNode.addChildNode(edgeNode)
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.tabBar.hidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
        
        if SessionService.sessionData!.debuggingEnabled {
            debugHelper = CameraDebugService()
        }
        
        frameCount = 0
        
        originalBrightness = UIScreen.mainScreen().brightness
        UIScreen.mainScreen().brightness = 1
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryCorrectedZVertical)
        
        session.startRunning()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        
        UIScreen.mainScreen().brightness = originalBrightness
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        motionManager.stopDeviceMotionUpdates()
        session.stopRunning()
    }
    
    override func updateViewConstraints() {
        view.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero) // needed to cover tabbar (49pt)
        
        tiltView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        progressView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 15)
        progressView.autoMatchDimension(.Width, toDimension: .Width, ofView: view, withOffset: -30)
        progressView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        
        instructionView.autoAlignAxis(.Horizontal, toSameAxisOfView: view, withMultiplier: 0.5)
        instructionView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        
        circleView.autoAlignAxis(.Horizontal, toSameAxisOfView: view)
        circleView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        circleView.autoSetDimensionsToSize(CGSize(width: 70, height: 70))
        
        recordButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -35)
        recordButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        recordButtonView.autoSetDimensionsToSize(CGSize(width: 70, height: 70))
        
        closeButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view, withMultiplier: 0.43)
        closeButtonView.autoAlignAxis(.Horizontal, toSameAxisOfView: recordButtonView)
        
        super.updateViewConstraints()
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
        
        scnView.frame = view.bounds
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
    
        line.firstMaterial?.diffuse.contents = UIColor(red: 239 / 255.0, green: 71 / 255.0, blue: 54 / 255.0, alpha: 1.0)
        
        return node
    }
    
    private func setupBall() {
        ballNode.geometry = SCNSphere(radius: CGFloat(0.04))
        ballNode.geometry?.firstMaterial?.diffuse.contents = UIColor.Accent
        
        scene.rootNode.addChildNode(ballNode)
    }
    
    private func updateBallPosition() {
        
        let maxSpeed = Float(0.008)
        let accelleration = Float(0.1)
        
        let vec = GLKVector3Make(0, 0, -1)
        let target = GLKMatrix4MultiplyVector3(stitcher.GetBallPosition(), vec)
        
        //print("Ball pos: \(res.x), \(res.y), \(res.z)")
        let ball = SCNVector3ToGLKVector3(ballNode.position)
        
        if ball.x == 0 && ball.y == 0 && ball.z == 0 {
            ballNode.position = SCNVector3FromGLKVector3(target)
        } else {
            var newSpeed = GLKVector3Subtract(target, ball)
            
            let dist = GLKVector3Length(newSpeed)
            
            if dist > maxSpeed {
                newSpeed = GLKVector3MultiplyScalar(GLKVector3Normalize(newSpeed), maxSpeed)
            }
            newSpeed = GLKVector3Subtract(newSpeed, ballSpeed)
            newSpeed = GLKVector3MultiplyScalar(newSpeed, accelleration)
            newSpeed = GLKVector3Add(newSpeed, ballSpeed)
            ballSpeed = newSpeed;
            ballNode.position = SCNVector3FromGLKVector3(GLKVector3Add(ball, ballSpeed))
        }
        
    }
    
    private func setupCamera() {
        authorizeCamera()
        
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
        videoDeviceOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if session.canAddOutput(videoDeviceOutput) {
            session.addOutput(videoDeviceOutput)
        }
        
        session.commitConfiguration()
    }
    
    private func authorizeCamera() {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { granted in
            if !granted {
                Async.main {
                    UIAlertView(
                        title: "Could not use camera!",
                        message: "This application does not have permission to use camera. Please update your privacy settings.",
                        delegate: self,
                        cancelButtonTitle: "OK").show()
                }
            }
        })
    }
 
    private func processSampleBuffer(sampleBuffer: CMSampleBufferRef) {
        
        if stitcher.IsFinished() {
            return
        }
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        if let pixelBuffer = pixelBuffer, motion = self.motionManager.deviceMotion {
            
            let r = CMRotationToGLKMatrix4(motion.attitude.rotationMatrix)
            CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
            
            var buf = ImageBuffer()
            buf.data = CVPixelBufferGetBaseAddress(pixelBuffer)
            buf.width = UInt32(CVPixelBufferGetWidth(pixelBuffer))
            buf.height = UInt32(CVPixelBufferGetHeight(pixelBuffer))
            
            stitcher.SetIdle(!self.viewModel.isRecording.value)
            stitcher.Push(r, buf)
            
            let errorVec = stitcher.GetAngularDistanceToBall()
            
            Async.main {
                self.viewModel.progress.value = Float(self.stitcher.GetRecordedImagesCount()) / Float(self.stitcher.GetImagesToRecordCount())
                self.viewModel.tiltAngle.value = Float(errorVec.z)
                self.viewModel.distXY.value = Float(sqrt(errorVec.x * errorVec.x + errorVec.y * errorVec.y))
            }
            
            updateBallPosition()
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
            
            // Take transform from the stitcher. 
            cameraNode.transform = SCNMatrix4FromGLKMatrix4(stitcher.GetCurrentRotation())
            
            if stitcher.IsPreviewImageAvailable() {
                self.previewImage = RotateCGImage(ImageBufferToCGImage(buf), orientation: .Left)
                stitcher.SetPreviewImageEnabled(false)
            }
            
            if stitcher.IsFinished() {
                stitcher.Finish()
                // needed since processSampleBuffer doesn't run on UI thread
                Async.main {
                    self.finish()
                }
            }

            //We always need debug data, even when not recording - the aligner is not paused when idle.
            debugHelper?.push(pixelBuffer, intrinsics: self.intrinsics, extrinsics: CMRotationToDoubleArray(motion.attitude.rotationMatrix), frameCount: frameCount)
        }
    }
    
    func finish() {
        // TODO remove
        if !stitcher.HasResults() {
            return
        }
        session.stopRunning()
        
        
        for child in scene.rootNode.childNodes {
            child.removeFromParentNode()
        }
        
        let assetSignalProducer = SignalProducer<OptographAsset, NoError> { sink, disposable in
            let preview = UIImageJPEGRepresentation(UIImage(CGImage: self.previewImage!), 0.8)

            sendNext(sink, OptographAsset.PreviewImage(preview!))
            
            if !disposable.disposed {
                let leftBuffer = self.stitcher.GetLeftResult()
                var leftCGImage: CGImage? = ImageBufferToCGImage(leftBuffer)
                let leftImageData = UIImageJPEGRepresentation(UIImage(CGImage: leftCGImage!), 0.8)
                self.stitcher.FreeImageBuffer(leftBuffer)
                leftCGImage = nil
                sendNext(sink, OptographAsset.LeftImage(leftImageData!))
            }
            
            if !disposable.disposed {
                let rightBuffer = self.stitcher.GetRightResult()
                var rightCGImage: CGImage? = ImageBufferToCGImage(rightBuffer)
                let rightImageData = UIImageJPEGRepresentation(UIImage(CGImage: rightCGImage!), 0.8)
                self.stitcher.FreeImageBuffer(rightBuffer)
                rightCGImage = nil
                sendNext(sink, OptographAsset.RightImage(rightImageData!))
            }
            
            self.stitcher.Dispose()

            if SessionService.sessionData!.debuggingEnabled {
                //self.debugHelper?.upload().startWithCompleted { sendCompleted(sink) }
                sendCompleted(sink)
            } else {
                sendCompleted(sink)
            }
            
            disposable.addDisposable {
                // TODO @emiswelt! insert code to cancel stitching
                // TODO @schickling: Just kill the thread. And then call dispose on the stitcher object.
                
            }
        }
        
        navigationController!.pushViewController(CreateOptographViewController(assetSignalProducer: assetSignalProducer), animated: false)
        navigationController!.viewControllers.removeAtIndex(1) // TODO remove at index: self
    }
    
    func cancel() {
        session.stopRunning()
        stitcher.Finish()
        stitcher.Dispose()
        navigationController?.popViewControllerAnimated(false)
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
        glLineWidth(6)
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
            border.strokeColor = isActive ? UIColor.Accent.CGColor : UIColor.whiteColor().CGColor
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

private class ProgressView: UIView {
    
    var progress: Float = 0 {
        didSet {
            layoutSubviews()
        }
    }
    var isActive = false {
        didSet {
            foregroundLine.backgroundColor = isActive ? UIColor.Accent.CGColor : UIColor.whiteColor().CGColor
            trackingPoint.backgroundColor = isActive ? UIColor.Accent.CGColor : UIColor.whiteColor().CGColor
        }
    }
    
    private let firstBackgroundLine = CALayer()
    private let secondBackgroundLine = CALayer()
    private let middlePoint = CALayer()
    private let endPoint = CALayer()
    private let foregroundLine = CALayer()
    private let trackingPoint = CALayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        firstBackgroundLine.backgroundColor = UIColor.whiteColor().CGColor
        layer.addSublayer(firstBackgroundLine)
        
        secondBackgroundLine.backgroundColor = UIColor.whiteColor().CGColor
        layer.addSublayer(secondBackgroundLine)
        
        middlePoint.borderColor = UIColor.whiteColor().CGColor
        middlePoint.borderWidth = 1
        middlePoint.cornerRadius = 3.5
        layer.addSublayer(middlePoint)
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
        
        middlePoint.hidden = progress > 0.5
        
        let width = bounds.width - 12
        let originX = bounds.origin.x + 6
        let originY = bounds.origin.y + 6
        
        firstBackgroundLine.frame = CGRect(x: originX, y: originY - 0.6, width: width * 0.5 - 3.5, height: 1.2)
        secondBackgroundLine.frame = CGRect(x: originX + width * 0.5 + 3.5, y: originY - 0.6, width: width * 0.5 - 3.5, height: 1.2)
        middlePoint.frame = CGRect(x: originX + width * 0.5 - 3.5, y: originY - 3.5, width: 7, height: 7)
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
        
        verticalLine.strokeColor = UIColor.Accent.CGColor
        verticalLine.fillColor = UIColor.clearColor().CGColor
        verticalLine.lineWidth = 2
        layer.addSublayer(verticalLine)
        
        ringSegment.strokeColor = UIColor.Accent.CGColor
        ringSegment.fillColor = UIColor.clearColor().CGColor
        ringSegment.lineWidth = 2
        layer.addSublayer(ringSegment)
        
        circleSegment.strokeColor = UIColor.clearColor().CGColor
        circleSegment.fillColor = UIColor.Accent.hatched2.CGColor
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
        let visibleLimit = Float(M_PI / 70)
        let criticalLimit = Float(M_PI / 50)
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
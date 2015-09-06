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
    private let stitcher = IosPipeline()
    private var frameCount = 0
    private var previewImageCount = 0
    private let intrinsics = CameraIntrinsics
    private var debugHelper: CameraDebugService?
    private var edges = [Edge: SCNNode]()
    private var previewImage: CGImage?
    
    // subviews
    private let progressView = ProgressView()
    private let instructionView = UILabel()
    private let circleView = DashedCircleView()
    private let recordButtonView = UIButton()
    private let closeButtonView = UIButton()
    
    // sphere
    private let cameraNode = SCNNode()
    private let scnView = SCNView()
    private let scene = SCNScene()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Answers.logCustomEventWithName("Camera", customAttributes: ["State": "Recording"])
        
        // layer for preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        setupScene()
        setupSelectionPoints()
        
        viewModel.progress.producer.start(next: { self.progressView.progress = $0 })
        viewModel.isRecording.producer.start(next: { self.progressView.isActive = $0 })
        view.addSubview(progressView)
        
        instructionView.font = UIFont.robotoOfSize(22, withType: .Medium)
        instructionView.numberOfLines = 0
        instructionView.textColor = .whiteColor()
        instructionView.textAlignment = .Center
        instructionView.rac_text <~ viewModel.instruction
        view.addSubview(instructionView)
        
        circleView.layer.cornerRadius = 35
        viewModel.isRecording.producer.start(next: { self.circleView.borderDashed = !$0 })
        view.addSubview(circleView)
        
        recordButtonView.rac_backgroundColor <~ viewModel.isRecording.producer.map { $0 ? BaseColor.hatched : UIColor.whiteColor().hatched }
//        let backgroundImage = UIImage(CIImage: .CIImage!, scale: 1, orientation: UIImageOrientation.Up)
//        recordButtonView.backgroundColor = BaseColor.hatched
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
        closeButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.navigationController?.popViewControllerAnimated(false)
            return RACSignal.empty()
        })
        view.addSubview(closeButtonView)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "finish"))
        
        setupCamera()
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        view.setNeedsUpdateConstraints()
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
        camera.zNear = 0.01
        camera.zFar = 10000
        camera.xFov = 65
        camera.yFov = 65 * Double(view.bounds.height / view.bounds.width)
        
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
        
        return node;
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
                
                
                if(stitcher.AreAdjacent(a, and: b)) {
                    
                    let edge = Edge(a, b)
                    
                    let vec = GLKVector3Make(0, 0, -1);
                    let posA = GLKMatrix4MultiplyVector3(a.extrinsics, vec)
                    let posB = GLKMatrix4MultiplyVector3(b.extrinsics, vec)
                    
                    let edgeNode = createLineNode(posA, posB: posB)
                    
                    edges[edge] = edgeNode;
                    
                    scene.rootNode.addChildNode(edgeNode)
                }
            }
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
        });
    }
 
    private func processSampleBuffer(sampleBuffer: CMSampleBufferRef) {
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
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
            
            // Take transform from the stitcher. 
            cameraNode.transform = SCNMatrix4FromGLKMatrix4(stitcher.GetCurrentRotation())
            
            if stitcher.IsPreviewImageAvailable() {
                
                let previewData = stitcher.GetPreviewImage()
                
                let currentPoint = stitcher.CurrentPoint()
                let previousPoint = stitcher.PreviousPoint()
                let edge = Edge(previousPoint, currentPoint)
                let nodeToRemove = edges[edge]
                nodeToRemove?.removeFromParentNode()
                edges.removeValueForKey(edge)
            
                let cgImage = ImageBufferToCGImage(previewData)
            
                
                let ratio = CGFloat(previewData.height) / CGFloat(previewData.width)
                let planeGeometry = SCNPlane(width: CGFloat(1), height: ratio)
                planeGeometry.firstMaterial?.doubleSided = true
                planeGeometry.firstMaterial?.diffuse.contents = cgImage
                
                let planeNode = SCNNode(geometry: planeGeometry)
                
                let R = stitcher.GetPreviewRotation()
                let T = GLKMatrix4MakeTranslation(0, 0, -Float(intrinsics[0]))
                planeNode.transform = SCNMatrix4FromGLKMatrix4(GLKMatrix4Multiply(R, T))
                
                scene.rootNode.addChildNode(planeNode)
                
                stitcher.FreeImageBuffer(previewData)
                
                previewImageCount++;
                
                if previewImageCount == 2 {
                    self.previewImage = RotateCGImage(ImageBufferToCGImage(buf), orientation: .Left)
                }
                
                if edges.isEmpty {
                    // needed since processSampleBuffer doesn't run on UI thread
                    Async.main {
                        self.finish()
                    }
                }
            
            }
            
            debugHelper?.push(pixelBuffer, intrinsics: self.intrinsics, extrinsics: CMRotationToDoubleArray(motion.attitude.rotationMatrix), frameCount: frameCount)
        }
    }
    
    func finish() {
        
        if !stitcher.HasResults() {
            return
        }
        
        for child in scene.rootNode.childNodes {
            child.removeFromParentNode()
        }
        
        let assetSignalProducer = SignalProducer<OptographAsset, NoError> { sink, disposable in
            let preview = UIImageJPEGRepresentation(UIImage(CGImage: self.previewImage!), 0.8)

            sendNext(sink, OptographAsset.PreviewImage(preview!))

            let leftBuffer = self.stitcher.GetLeftResult()
            var leftCGImage: CGImage? = ImageBufferToCGImage(leftBuffer)
            let leftImageData = UIImageJPEGRepresentation(UIImage(CGImage: leftCGImage!), 0.8)
            self.stitcher.FreeImageBuffer(leftBuffer)
            leftCGImage = nil
            sendNext(sink, OptographAsset.LeftImage(leftImageData!))

            let rightBuffer = self.stitcher.GetRightResult()
            var rightCGImage: CGImage? = ImageBufferToCGImage(rightBuffer)
            let rightImageData = UIImageJPEGRepresentation(UIImage(CGImage: rightCGImage!), 0.8)
            self.stitcher.FreeImageBuffer(rightBuffer)
            rightCGImage = nil

            sendNext(sink, OptographAsset.RightImage(rightImageData!))
            
            if SessionService.sessionData!.debuggingEnabled {
                self.debugHelper?.upload()
                    .start(completed: {
                        sendCompleted(sink)
                    })
            } else {
                sendCompleted(sink)
            }
            
            disposable.addDisposable {
                // TODO @emiswelt! insert code to cancel stitching
            }
        }
        
        navigationController!.pushViewController(CreateOptographViewController(assetSignalProducer: assetSignalProducer), animated: false)
        navigationController!.viewControllers.removeAtIndex(1)
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
        glLineWidth(5)
        glColor4f(1, 0, 0, 1)
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
    
    var borderDashed = true {
        didSet {
            border.lineDashPattern = borderDashed ? [19, 8] : nil
        }
    }
    
    private let border = CAShapeLayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        border.strokeColor = UIColor.whiteColor().CGColor
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
            layoutSubviews()
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
        
        let width = bounds.width - 12
        let originX = bounds.origin.x + 6
        let originY = bounds.origin.y + 6
        
        foregroundLine.backgroundColor = isActive ? BaseColor.CGColor : UIColor.whiteColor().CGColor
        trackingPoint.backgroundColor = isActive ? BaseColor.CGColor : UIColor.whiteColor().CGColor
        
        middlePoint.hidden = progress > 0.5
        
        firstBackgroundLine.frame = CGRect(x: originX, y: originY - 0.6, width: width * 0.5 - 3.5, height: 1.2)
        secondBackgroundLine.frame = CGRect(x: originX + width * 0.5 + 3.5, y: originY - 0.6, width: width * 0.5 - 3.5, height: 1.2)
        middlePoint.frame = CGRect(x: originX + width * 0.5 - 3.5, y: originY - 3.5, width: 7, height: 7)
        endPoint.frame = CGRect(x: width + 3.5, y: originY - 3.5, width: 7, height: 7)
        foregroundLine.frame = CGRect(x: originX, y: originY - 1, width: width * CGFloat(progress), height: 2)
        trackingPoint.frame = CGRect(x: originX + width * CGFloat(progress) - 6, y: originY - 6, width: 12, height: 12)
    }
}
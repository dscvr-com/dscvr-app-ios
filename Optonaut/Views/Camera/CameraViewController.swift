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

struct Edge: Hashable {
    let one: SelectionPoint
    let two: SelectionPoint
    
    var hashValue: Int {
        return one.id.hashValue ^ two.id.hashValue
    }
    
    init(_ one: SelectionPoint, _ two: SelectionPoint) {
        self.one = one
        self.two = two
    }
}

func == (lhs: Edge, rhs: Edge) -> Bool {
    return lhs.one.id == rhs.one.id && lhs.two.id == rhs.two.id
}

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
    
    var originalBrightness: CGFloat!
    
    // stitcher pointer and variables
    
    let stitcher = IosPipeline()
    
    var frameCount = 0
    let intrinsics = CameraIntrinsics
    
    
    var debugHelper: CameraDebugHelper?
    var edges = [Edge: SCNNode]()
    
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
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "finish"))
        
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
        
        originalBrightness = UIScreen.mainScreen().brightness
        UIScreen.mainScreen().brightness = 1
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = true
        
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
        
        UIScreen.mainScreen().brightness = originalBrightness
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = false
        
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
        print("Adding points")
        let points = stitcher.GetSelectionPoints().map( { (wrapped: NSValue) -> SelectionPoint in
            var point = SelectionPoint()
            wrapped.getValue(&point)
            return point;
        })
        
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
            
            //print("Push!");

            stitcher.Push(r, buf)
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly)
            
            debugHelper?.push(pixelBuffer, intrinsics: self.intrinsics, extrinsics: CMRotationToDoubleArray(motion.attitude.rotationMatrix), frameCount: frameCount)
            
            //No, that's not a good idea.
            self.cameraNode.transform = SCNMatrix4FromGLKMatrix4(stitcher.GetCurrentRotation())
            
            if(stitcher.IsPreviewImageValialble()) {
                
                let previewData = stitcher.GetPreviewImage()
                
                let currentPoint = stitcher.CurrentPoint()
                let previousPoint = stitcher.PreviousPoint()
                let edge = Edge(previousPoint, currentPoint)
                let nodeToRemove = edges[edge]
                nodeToRemove?.removeFromParentNode()
                edges.removeValueForKey(edge)
                //print("Preview Image!")
            
                let cgImage = ImageBufferToCGImage(previewData);
                
                let ratio = CGFloat(previewData.height) / CGFloat(previewData.width)
                let planeGeometry = SCNPlane(width: CGFloat(1), height: ratio)
                planeGeometry.firstMaterial?.doubleSided = true
                planeGeometry.firstMaterial?.diffuse.contents = cgImage
                
                let planeNode = SCNNode(geometry: planeGeometry)
                
                let L = GLKMatrix4MakeRotation(Float(M_PI_2), 0, 0, -1)
                let R = stitcher.GetPreviewRotation()
                
                let T = GLKMatrix4MakeTranslation(0, 0, -Float(intrinsics[0]))
                let TL = GLKMatrix4Multiply(T, L)
                planeNode.transform = SCNMatrix4FromGLKMatrix4(GLKMatrix4Multiply(R, TL))
                
                scene.rootNode.addChildNode(planeNode)
                
                stitcher.FreeImageBuffer(previewData)
                
                if edges.isEmpty {
                    dispatch_async(dispatch_get_main_queue(), finish)
                }
            }

        }
    }
    
    func finish() {
        
        //This code can (and should be executed asynchronously while the user enters
        //the description.
        print("Finalizing")
        
        let leftBuffer = stitcher.GetLeftResult()
        let leftCGImage = ImageBufferToCGImage(leftBuffer)
        let leftImageData = UIImageJPEGRepresentation(UIImage(CGImage: leftCGImage), 1)
        stitcher.FreeImageBuffer(leftBuffer)
        
        let rightBuffer = stitcher.GetRightResult()
        let rightCGImage = ImageBufferToCGImage(rightBuffer)
        let rightImageData = UIImageJPEGRepresentation(UIImage(CGImage: rightCGImage), 1)
        stitcher.FreeImageBuffer(rightBuffer)
        
        let optograph = Optograph.newInstance() as! Optograph
        // TODO add person reference
        try! optograph.saveImages(leftImage: leftImageData!, rightImage: rightImageData!)
    
        navigationController!.pushViewController(CreateOptographViewController(optograph: optograph), animated: false)
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
    
        /*if let motion = self.motionManager.deviceMotion {
            
            let rGlk = CMRotationToGLKMatrix4(motion.attitude.rotationMatrix);
            
            self.cameraNode.transform = SCNMatrix4FromGLKMatrix4(rGlk)
        
        }*/
    }
    
}
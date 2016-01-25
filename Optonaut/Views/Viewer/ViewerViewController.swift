import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import Device
import CoreGraphics
import Mixpanel
import ReactiveCocoa
import Crashlytics
import CardboardParams
import Async
import SwiftyUserDefaults
import Kingfisher
import SpriteKit

class ViewerViewController: UIViewController  {
    
    private let orientation: UIInterfaceOrientation
    private let optograph: Optograph
    
    private var leftRenderDelegate: CubeRenderDelegate!
    private var rightRenderDelegate: CubeRenderDelegate!
    private var leftScnView: SCNView!
    private var rightScnView: SCNView!
    private let separatorLayer = CALayer()
    private var headset: CardboardParams
    private let screen: ScreenParams
    
    private var leftProgram: DistortionProgram!
    private var rightProgram: DistortionProgram!
    
    private var rotationDisposable: Disposable?
    
    private let settingsButtonView = BoundingButton()
    private var glassesSelectionView: GlassesSelectionView?
    private let leftLoadingView = UIActivityIndicatorView()
    private let rightLoadingView = UIActivityIndicatorView()
    
    private let leftCache: CubeImageCache
    private let rightCache: CubeImageCache
    
    required init(orientation: UIInterfaceOrientation, optograph: Optograph) {
        self.orientation = orientation
        self.optograph = optograph
        
        // Please set this to meaningful default values.
        
        switch UIDevice.currentDevice().deviceType {
        case .IPhone4S: screen = ScreenParams(device: .IPhone4S)
        case .IPhone5: screen = ScreenParams(device: .IPhone5)
        case .IPhone5C: screen = ScreenParams(device: .IPhone5C)
        case .IPhone5S: screen = ScreenParams(device: .IPhone5S)
        case .IPhone6: screen = ScreenParams(device: .IPhone6)
        case .IPhone6Plus: screen = ScreenParams(device: .IPhone6Plus)
        case .IPhone6S: screen = ScreenParams(device: .IPhone6S)
        case .IPhone6SPlus: screen = ScreenParams(device: .IPhone6SPlus)
        default: fatalError("device not supported")
        }
       
        headset = CardboardParams.fromBase64(Defaults[.SessionVRGlasses]).value!
    
        print("Headset: \(headset.vendor) \(headset.model)")
        
        let textureSize = CGFloat(512)
        
        print(optograph.ID)
        
        leftCache = CubeImageCache(optographID: optograph.ID, side: .Left, textureSize: textureSize)
        rightCache = CubeImageCache(optographID: optograph.ID, side: .Right, textureSize: textureSize)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    private func createRenderDelegates() {
        leftRenderDelegate = CubeRenderDelegate(rotationMatrixSource: HeadTrackerRotationSource.Instance, fov: leftProgram.fov, cameraOffset: Float(-0.2))
        rightRenderDelegate = CubeRenderDelegate(rotationMatrixSource: HeadTrackerRotationSource.Instance, fov: rightProgram.fov, cameraOffset: Float(0.2))
        
        leftScnView.scene = leftRenderDelegate.scene
        leftScnView.delegate = leftRenderDelegate
        
        for plane in leftRenderDelegate.planes {
            plane.1.geometry!.firstMaterial!.diffuse.contents = UIColor.redColor()
        }
        
        for plane in rightRenderDelegate.planes {
            plane.1.geometry!.firstMaterial!.diffuse.contents = UIColor.greenColor()
        }
        
        rightScnView.scene = rightRenderDelegate.scene
        rightScnView.delegate = rightRenderDelegate
    }
    
    private func applyDistortionShader() {
        leftScnView.technique = leftProgram.technique
        rightScnView.technique = rightProgram.technique
        leftRenderDelegate.fov = leftProgram.fov
        rightRenderDelegate.fov = rightProgram.fov
    }
    
    private func loadDistortionShader() {
        if headset.vendor.containsString("Zeiss") && headset.model == "VR ONE" {
            leftProgram = VROneDistortionProgram(isLeft: true)
            rightProgram = VROneDistortionProgram(isLeft: false)
        } else {
            if leftProgram == nil || leftProgram is VROneDistortionProgram {
                leftProgram = CardboardDistortionProgram(params: headset, screen: screen, eye: Eye.Left)
                rightProgram = CardboardDistortionProgram(params: headset, screen: screen, eye: Eye.Right)
            } else {
                leftProgram.setParameters(headset, screen: screen, eye: .Left)
                rightProgram.setParameters(headset, screen: screen, eye: .Right)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let width = view.frame.width
        let height = view.frame.height
        
        leftScnView = ViewerViewController.createScnView(CGRect(x: 0, y: 0, width: width, height: height / 2))
        rightScnView = ViewerViewController.createScnView(CGRect(x: 0, y: height / 2, width: width, height: height / 2))
        
        loadDistortionShader()
        createRenderDelegates()
        applyDistortionShader()
        
        view.addSubview(rightScnView)
        view.addSubview(leftScnView)
        
        separatorLayer.backgroundColor = UIColor.whiteColor().CGColor
        separatorLayer.frame = CGRect(x: 50, y: view.frame.height / 2 - 2, width: view.frame.width - 50, height: 4)
        view.layer.addSublayer(separatorLayer)
        
        leftLoadingView.activityIndicatorViewStyle = .WhiteLarge
        leftLoadingView.startAnimating()
        leftLoadingView.hidesWhenStopped = true
        leftLoadingView.frame = CGRect(x: view.frame.width / 2 - 20, y: view.frame.height / 4 - 20, width: 40, height: 40)
        view.addSubview(leftLoadingView)
        
        rightLoadingView.activityIndicatorViewStyle = .WhiteLarge
        rightLoadingView.startAnimating()
        rightLoadingView.hidesWhenStopped = true
        rightLoadingView.frame = CGRect(x: view.frame.width / 2 - 20, y: view.frame.height * 3 / 4 - 20, width: 40, height: 40)
        view.addSubview(rightLoadingView)
        
        settingsButtonView.frame = CGRect(x: 10, y: view.frame.height / 2 - 15, width: 30, height: 30)
//        settingsButtonView.setTitle(String.iconWithName(.Settings), forState: .Normal)
        settingsButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        settingsButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        settingsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showGlassesSelection"))
        view.addSubview(settingsButtonView)
        
        if !Defaults[.SessionVRGlassesSelected] {
            showGlassesSelection()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.Viewer")

        navigationController?.setNavigationBarHidden(true, animated: false)
        ScreenService.sharedInstance.max()
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        tabController!.hideUI()
        
        var popActivated = false // needed when viewer was opened without rotation
        HeadTrackerRotationSource.Instance.start()
        RotationService.sharedInstance.rotationEnable()
        
        rotationDisposable = RotationService.sharedInstance.rotationSignal?
            .skipRepeats()
            .observeOn(UIScheduler())
            .observeNext { [weak self] orientation in
                switch orientation {
                case .Portrait:
                    if popActivated {
                        self?.navigationController?.popViewControllerAnimated(false)
                    }
                default:
                    popActivated = true
                }
            }
        
        
        let leftImageCallback = { [weak self] (image: SKTexture, index: CubeImageCache.Index) -> Void in
            Async.main {
                self?.leftRenderDelegate.setTexture(image, forIndex: index)
                self?.leftScnView.prepareObject(self!.leftRenderDelegate!.scene, shouldAbortBlock: nil)
                self?.leftLoadingView.stopAnimating()
            }
        }
        
        let rightImageCallback = { [weak self] (image: SKTexture, index: CubeImageCache.Index) -> Void in
            Async.main {
                self?.rightRenderDelegate.setTexture(image, forIndex: index)
                self?.rightLoadingView.stopAnimating()
            }
        }
        
        
        let defaultIndices = [
            CubeImageCache.Index(face: 0, x: 0, y: 0, d: 1),
            CubeImageCache.Index(face: 1, x: 0, y: 0, d: 1),
            CubeImageCache.Index(face: 2, x: 0, y: 0, d: 1),
            CubeImageCache.Index(face: 3, x: 0, y: 0, d: 1),
            CubeImageCache.Index(face: 4, x: 0, y: 0, d: 1),
            CubeImageCache.Index(face: 5, x: 0, y: 0, d: 1),
        ]
        
        Async.userInteractive { [weak self] in
            for cubeIndex in defaultIndices {
                self?.leftCache.get(cubeIndex, callback: leftImageCallback)
                self?.rightCache.get(cubeIndex, callback: rightImageCallback)
            }
        }
        
//        leftDownloadDisposable = imageManager.downloader.downloadImageForURL(ImageURL(optograph.leftTextureAssetID))
//            .observeOnMain()
//            .startWithNext { [weak self] image in
////                self?.leftRenderDelegate.image = image
//                self?.imageManager.cache.clearMemoryCache()
//                self?.leftLoadingView.stopAnimating()
//            }
//        
//        rightDownloadDisposable = imageManager.downloader.downloadImageForURL(ImageURL(optograph.rightTextureAssetID))
//            .observeOnMain()
//            .startWithNext { [weak self] image in
////                self?.rightRenderDelegate.image = image
//                self?.imageManager.cache.clearMemoryCache()
//                self?.rightLoadingView.stopAnimating()
//            }
    }
    
    func setViewerParameters(headset: CardboardParams) {
        self.headset = headset
        
        loadDistortionShader()
        applyDistortionShader()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.Viewer", properties: ["optograph_id": optograph.ID, "optograph_description" : optograph.text])
        
        rotationDisposable?.dispose()
        RotationService.sharedInstance.rotationDisable()
        HeadTrackerRotationSource.Instance.stop()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        applyDistortionShader()
    }
    
    override func viewWillDisappear(animated: Bool) {
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        ScreenService.sharedInstance.reset()
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        super.viewWillDisappear(animated)
    }
    
    private static func createScnView(frame: CGRect) -> SCNView {
        var scnView: SCNView
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: frame, options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
        } else {
            scnView = SCNView(frame: frame)
        }
        
        scnView.backgroundColor = .blackColor()
        scnView.playing = true
        
        return scnView
    }
    
    func showGlassesSelection() {
        glassesSelectionView = GlassesSelectionView()
        glassesSelectionView!.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        glassesSelectionView!.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        glassesSelectionView!.glasses = CardboardParams.fromBase64(Defaults[.SessionVRGlasses]).value!.model
        
        glassesSelectionView!.closeCallback = { [weak self] in
            Defaults[.SessionVRGlassesSelected] = true
            self?.glassesSelectionView?.removeFromSuperview()
        }
        
        glassesSelectionView!.paramsCallback = { [weak self] params in
            Defaults[.SessionVRGlassesSelected] = true
            self?.setViewerParameters(params)
        }
        
        view.addSubview(glassesSelectionView!)
    }
}

private class GlassesSelectionView: UIView {
    
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    
    private let cancelButtonView = UIButton()
    private let titleTextView = UILabel()
    private let glassesIconView = UILabel()
    private let glassesTextView = UILabel()
    private let qrcodeIconView = UILabel()
    private let qrcodeTextView = UILabel()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let loadingIndicatorView = UIActivityIndicatorView()
    
    private var loading: Bool = false
    
    var closeCallback: (() -> ())?
    var paramsCallback: (CardboardParams -> ())?
    
    var captureSession: AVCaptureSession?
    var code: String?
    
    var glasses: String? {
        didSet {
            glassesTextView.text = glasses
        }
    }
    
    init () {
        super.init(frame: CGRectZero)
        
        addSubview(blurView)
        
//        cancelButtonView.setTitle(String.iconWithName(.Cross), forState: .Normal)
        cancelButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        cancelButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        cancelButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        addSubview(cancelButtonView)
        
        titleTextView.text = "Choose your VR glasses"
        titleTextView.textColor = .whiteColor()
        titleTextView.textAlignment = .Center
        titleTextView.font = UIFont.displayOfSize(35, withType: .Thin)
        addSubview(titleTextView)
        
//        glassesIconView.text = String.iconWithName(.Cardboard)
        glassesIconView.textColor = .whiteColor()
        glassesIconView.textAlignment = .Center
        glassesIconView.font = UIFont.iconOfSize(73)
        glassesIconView.userInteractionEnabled = true
        glassesIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        addSubview(glassesIconView)
        
        glassesTextView.font = UIFont.displayOfSize(15, withType: .Semibold)
        glassesTextView.textColor = .whiteColor()
        glassesTextView.textAlignment = .Center
        glassesTextView.userInteractionEnabled = true
        glassesTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        addSubview(glassesTextView)
        
//        qrcodeIconView.text = String.iconWithName(.Qrcode)
        qrcodeIconView.font = UIFont.iconOfSize(50)
        qrcodeIconView.textColor = .whiteColor()
        qrcodeIconView.textAlignment = .Center
        qrcodeIconView.userInteractionEnabled = true
        qrcodeIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "scan"))
        addSubview(qrcodeIconView)
        
        qrcodeTextView.font = UIFont.displayOfSize(15, withType: .Semibold)
        qrcodeTextView.textColor = .whiteColor()
        qrcodeTextView.text = "Scan QR code"
        qrcodeTextView.textAlignment = .Center
        qrcodeTextView.userInteractionEnabled = true
        qrcodeTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "scan"))
        addSubview(qrcodeTextView)
        
        loadingIndicatorView.activityIndicatorViewStyle = .WhiteLarge
        addSubview(loadingIndicatorView)
        
        Mixpanel.sharedInstance().track("View.CardboardSelection")
    }
    
    deinit {
        logRetain()
    }
    
    private func updateLoading(loading: Bool) {
        titleTextView.hidden = loading
        glassesIconView.hidden = loading
        glassesTextView.hidden = loading
        qrcodeIconView.hidden = loading
        qrcodeTextView.hidden = loading
        previewLayer?.hidden = loading
        loadingIndicatorView.hidden = !loading
        
        if loading {
            loadingIndicatorView.startAnimating()
        } else {
            loadingIndicatorView.stopAnimating()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private override func layoutSubviews() {
        blurView.frame = bounds
        
        cancelButtonView.frame = CGRect(x: bounds.width - 50, y: 20, width: 30, height: 30)
        
        titleTextView.frame = CGRect(x: 0, y: bounds.height * 0.25 - 19, width: bounds.width, height: 38)
        
        glassesIconView.frame = CGRect(x: bounds.width * 0.37 - 37, y: bounds.height * 0.5, width: 74, height: 50)
        glassesTextView.frame = CGRect(x: bounds.width * 0.37 - 100, y: bounds.height * 0.5 + 70, width: 200, height: 20)
        
        qrcodeIconView.frame = CGRect(x: bounds.width * 0.63 - 37, y: bounds.height * 0.5, width: 74, height: 50)
        qrcodeTextView.frame = CGRect(x: bounds.width * 0.63 - 100, y: bounds.height * 0.5 + 70, width: 200, height: 20)
        
        loadingIndicatorView.frame = CGRect(x: bounds.width * 0.5 - 20, y: bounds.height * 0.5 - 20, width: 40, height: 40)
        
        super.layoutSubviews()
        
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        let videoCaptureDevice: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        try! videoCaptureDevice.lockForConfiguration()
        videoCaptureDevice.focusMode = .ContinuousAutoFocus
        videoCaptureDevice.unlockForConfiguration()
        
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }
        
        if captureSession!.canAddInput(videoInput) {
            captureSession!.addInput(videoInput)
        } else {
            print("Could not add video input")
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession!.canAddOutput(metadataOutput) {
            captureSession!.addOutput(metadataOutput)
            
            let queue = dispatch_queue_create("qr_scan_queue", DISPATCH_QUEUE_SERIAL)
            metadataOutput.setMetadataObjectsDelegate(self, queue: queue)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeDataMatrixCode]
        } else {
            print("Could not add metadata output")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer!.transform = CATransform3DMakeRotation(CGFloat(-M_PI_2), 0, 0, 1)
        previewLayer!.frame = CGRect(x: 70, y: 0, width: bounds.width - 150, height: bounds.height)
        layer.addSublayer(previewLayer!)
        
        captureSession!.startRunning()
    }
    
    @objc func cancel() {
        captureSession?.stopRunning()
        closeCallback?()
    }
    
    @objc func scan() {
        setupCamera()
    }
}

extension GlassesSelectionView: AVCaptureMetadataOutputObjectsDelegate {
    @objc func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if loading {
            return
        }
        
        for metadata in metadataObjects {
            let readableObject = metadata as! AVMetadataMachineReadableCodeObject
            let code = readableObject.stringValue
            
            if !code.isEmpty {
                
                loading = true
                captureSession?.stopRunning()
                
                Async.main { [weak self] in
                    self?.updateLoading(true)
                }
                
                let shortUrl = code.containsString("http://") ? code : "http://\(code)"
                
                CardboardParams.fromUrl(shortUrl) { [weak self] result in
                    
                    switch result {
                    case let .Success(params):
                        Async.main {
                            Defaults[.SessionVRGlasses] = params.compressedRepresentation.base64EncodedStringWithOptions([])
                            
                            let cardboardDescription = "\(params.vendor) \(params.model)"
                            Mixpanel.sharedInstance().track("View.CardboardSelection.Scanned", properties: ["cardboard": cardboardDescription, "url" : shortUrl])
                            Mixpanel.sharedInstance().people.set(["Last scanned Cardboard": cardboardDescription])
                            self?.paramsCallback?(params)
                            self?.cancel()
                        }
                    case let .Failure(error):
                        print(error)
                        self?.loading = false
                        self?.captureSession?.startRunning()
                        
                        Async.main { [weak self] in
                            self?.updateLoading(false)
                        }
                    }
                    
                }
            }
        }
    }
}
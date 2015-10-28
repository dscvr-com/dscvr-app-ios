import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import Device
import CoreGraphics
import Mixpanel
import WebImage
import ReactiveCocoa
import Crashlytics
import GoogleCardboardParser
import Async

class ViewerViewController: UIViewController  {
    
    private let orientation: UIInterfaceOrientation
    private let optograph: Optograph
    
    private var leftRenderDelegate: StereoRenderDelegate!
    private var rightRenderDelegate: StereoRenderDelegate!
    private var leftScnView: SCNView!
    private var rightScnView: SCNView!
    private let separatorLayer = CALayer()
    private var headset: CardboardParams
    private let screen: ScreenParams
    
    private var leftProgram: DistortionProgram!
    private var rightProgram: DistortionProgram!
    
    private var rotationDisposable: Disposable?
    private var leftDownloadDisposable: Disposable?
    private var rightDownloadDisposable: Disposable?
    
    private let settingsButtonView = UIButton()
    private var glassesSelectionView: GlassesSelectionView?
    
    required init(orientation: UIInterfaceOrientation, optograph: Optograph) {
        self.orientation = orientation
        self.optograph = optograph
        
        // Please set this to meaningful default values.
        
        switch UIDevice.currentDevice().deviceType {
        case .IPhone4S: screen = ScreenParams.iPhone4
        case .IPhone5: screen = ScreenParams.iPhone5
        case .IPhone5S, .IPhone5C: screen = ScreenParams.iPhone5s
        case .IPhone6, .IPhone6S: screen = ScreenParams.iPhone6
        case .IPhone6Plus, .IPhone6SPlus: screen = ScreenParams.iPhone6Plus
        default: fatalError("device not supported")
        }
        
        headset = try! CardboardFactory.CardboardParamsFromBase64(SessionService.sessionData!.vrGlasses)!
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let width = view.frame.width
        let height = view.frame.height
        
        leftScnView = ViewerViewController.createScnView(CGRect(x: 0, y: 0, width: width, height: height / 2))
        rightScnView = ViewerViewController.createScnView(CGRect(x: 0, y: height / 2, width: width, height: height / 2))
        
        leftProgram = DistortionProgram(params: headset, screen: screen, eye: Eye.Left)
        rightProgram = DistortionProgram(params: headset, screen: screen, eye: Eye.Right)
        
        leftRenderDelegate = StereoRenderDelegate(rotationMatrixSource: HeadTrackerRotationSource.Instance, width: leftScnView.frame.width, height: leftScnView.frame.height, fov: leftProgram.fov)
        rightRenderDelegate = StereoRenderDelegate(rotationMatrixSource: HeadTrackerRotationSource.Instance, width: rightScnView.frame.width, height: rightScnView.frame.height, fov: rightProgram.fov)
        
        leftDownloadDisposable = SDWebImageManager.sharedManager().downloadImageForURL(optograph.leftTextureAssetURL)
            .startWithNext { [weak self] image in
                self?.leftRenderDelegate.image = image
                self?.leftDownloadDisposable = nil
            }
        rightDownloadDisposable = SDWebImageManager.sharedManager().downloadImageForURL(optograph.rightTextureAssetURL)
            .startWithNext { [weak self] image in
                self?.rightRenderDelegate.image = image
                self?.rightDownloadDisposable = nil
            }
            
        leftScnView.scene = leftRenderDelegate.scene
        leftScnView.delegate = leftRenderDelegate
        
        rightScnView.scene = rightRenderDelegate.scene
        rightScnView.delegate = rightRenderDelegate

        leftScnView.technique = leftProgram.technique
        rightScnView.technique = rightProgram.technique
        
        view.addSubview(rightScnView)
        view.addSubview(leftScnView)
        
        separatorLayer.backgroundColor = UIColor.whiteColor().CGColor
        separatorLayer.frame = CGRect(x: 50, y: view.frame.height / 2 - 2, width: view.frame.width - 50, height: 4)
        view.layer.addSublayer(separatorLayer)
        
        settingsButtonView.frame = CGRect(x: 10, y: view.frame.height / 2 - 15, width: 30, height: 30)
        settingsButtonView.setTitle(String.iconWithName(.Settings), forState: .Normal)
        settingsButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        settingsButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        settingsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showGlassesSelection"))
        view.addSubview(settingsButtonView)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.Viewer")

        tabBarController?.tabBar.hidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        ScreenService.sharedInstance.max()
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = true
        
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
    }
    
    func setViewerParameters(headset: CardboardParams) {
        self.headset = headset
        
        leftProgram.setParameters(headset, screen: screen, eye: .Left)
        rightProgram.setParameters(headset, screen: screen, eye: .Right)
        
        leftRenderDelegate.fov = leftProgram.fov
        rightRenderDelegate.fov = rightProgram.fov
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.Viewer", properties: ["optograph_id": optograph.ID])
        
        rotationDisposable?.dispose()
    }
    
    override func viewWillDisappear(animated: Bool) {
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        ScreenService.sharedInstance.reset()
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        leftDownloadDisposable?.dispose()
        rightDownloadDisposable?.dispose()
        
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
        glassesSelectionView!.glasses = try! CardboardFactory.CardboardParamsFromBase64(SessionService.sessionData!.vrGlasses)!.model
        
        glassesSelectionView!.closeCallback = { [weak self] in
            self?.glassesSelectionView?.removeFromSuperview()
        }
        
        glassesSelectionView!.paramsCallback = { [weak self] params in
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
        
        cancelButtonView.setTitle(String.iconWithName(.Cross), forState: .Normal)
        cancelButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        cancelButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        cancelButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        addSubview(cancelButtonView)
        
        titleTextView.text = "Choose your VR glasses"
        titleTextView.textColor = .whiteColor()
        titleTextView.textAlignment = .Center
        titleTextView.font = UIFont.displayOfSize(35, withType: .Thin)
        addSubview(titleTextView)
        
        glassesIconView.text = String.iconWithName(.Cardboard)
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
        
        qrcodeIconView.text = String.iconWithName(.Qrcode)
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
                
                CardboardFactory.CardboardParamsFromUrl("http://\(code)") { [weak self] (params, error) in
                    
                    guard let params = params else {
                        print(error)
                        
                        self?.loading = false
                        self?.captureSession?.startRunning()
                        
                        Async.main { [weak self] in
                            self?.updateLoading(false)
                        }
                        
                        return
                    }
                    
                    Async.main {
                        self?.paramsCallback?(params)
                        SessionService.sessionData!.vrGlasses = params.compressedRepresentation.base64EncodedStringWithOptions([])
                        self?.cancel()
                    }
                }
            }
        }
    }
}
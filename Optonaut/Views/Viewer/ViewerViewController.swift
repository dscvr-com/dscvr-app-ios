import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import Device
import CoreGraphics
import Mixpanel
import ReactiveSwift
import Crashlytics
import CardboardParams
import Async
import SwiftyUserDefaults
import SpriteKit

private let queue = DispatchQueue(label: "viewer", attributes: [])

class ViewerViewController: UIViewController  {
    
    fileprivate let orientation: UIInterfaceOrientation
    fileprivate let optograph: Optograph
    
    fileprivate var leftRenderDelegate: CubeRenderDelegate!
    fileprivate var rightRenderDelegate: CubeRenderDelegate!
    fileprivate var leftScnView: SCNView!
    fileprivate var rightScnView: SCNView!
    fileprivate let separatorLayer = CALayer()
    fileprivate var headset: CardboardParams
    fileprivate let screen: ScreenParams
    
    fileprivate var leftProgram: DistortionProgram!
    fileprivate var rightProgram: DistortionProgram!
    
    fileprivate var rotationDisposable: Disposable?
    
    fileprivate let settingsButtonView = BoundingButton()
    fileprivate var glassesSelectionView: GlassesSelectionView?
    fileprivate let leftLoadingView = UIActivityIndicatorView()
    fileprivate let rightLoadingView = UIActivityIndicatorView()
    
    fileprivate let leftCache: CubeImageCache
    fileprivate let rightCache: CubeImageCache
    
    required init(orientation: UIInterfaceOrientation, optograph: Optograph) {
        self.orientation = orientation
        self.optograph = optograph
        
        // Please set this to meaningful default values.
        
        switch UIDevice.current.deviceType {
        case .iPhone4S: screen = ScreenParams(device: .iPhone4S)
        case .iPhone5: screen = ScreenParams(device: .iPhone5)
        case .iPhone5C: screen = ScreenParams(device: .iPhone5C)
        case .iPhone5S: screen = ScreenParams(device: .iPhone5S)
        case .iPhone6: screen = ScreenParams(device: .iPhone6)
        case .iPhone6Plus: screen = ScreenParams(device: .iPhone6Plus)
        case .iPhone6S: screen = ScreenParams(device: .iPhone6S)
        case .iPhone6SPlus: screen = ScreenParams(device: .iPhone6SPlus)
        case .iPhone7: screen = ScreenParams(device: .iPhone6S)
        case .iPhone7Plus: screen = ScreenParams(device: .iPhone6SPlus)
        default: screen = ScreenParams(device: .iPhone6S)
        }
        
        print("Creating VR headset: \(Defaults[.SessionVRGlasses])")
        
        headset = CardboardParams.fromBase64(Defaults[.SessionVRGlasses]).value!
        
        print("Headset: \(headset.vendor) \(headset.model)")
        
        let textureSize = getTextureWidth(UIScreen.main.bounds.height / 2, hfov: 65) // 90 is a guess. A better value might be needed
        
        leftCache = CubeImageCache(optographID: optograph.ID, side: .left, textureSize: textureSize)
        rightCache = CubeImageCache(optographID: optograph.ID, side: .right, textureSize: textureSize)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    fileprivate func createRenderDelegates() {
        InvertableHeadTrackerRotationSource.InvertableInstance.inverted = orientation == .landscapeLeft
        
        leftRenderDelegate = CubeRenderDelegate(rotationMatrixSource: InvertableHeadTrackerRotationSource.InvertableInstance, fov: leftProgram.fov, cameraOffset: Float(-0.2), cubeFaceCount: 1, autoDispose: false)
        leftRenderDelegate.scnView = leftScnView
        rightRenderDelegate = CubeRenderDelegate(rotationMatrixSource: InvertableHeadTrackerRotationSource.InvertableInstance, fov: rightProgram.fov, cameraOffset: Float(0.2), cubeFaceCount: 1, autoDispose: false)
        rightRenderDelegate.scnView = rightScnView
        
        leftScnView.scene = leftRenderDelegate.scene
        leftScnView.delegate = leftRenderDelegate
        
        rightScnView.scene = rightRenderDelegate.scene
        rightScnView.delegate = rightRenderDelegate
    }
    
    fileprivate func applyDistortionShader() {
        leftScnView.technique = leftProgram.technique
        rightScnView.technique = rightProgram.technique
        leftRenderDelegate.fov = leftProgram.fov
        rightRenderDelegate.fov = rightProgram.fov
    }
    
    fileprivate func loadDistortionShader() {
        if headset.vendor.contains("Zeiss") && headset.model == "VR ONE" {
            leftProgram = VROneDistortionProgram(isLeft: true)
            rightProgram = VROneDistortionProgram(isLeft: false)
        } else {
            if leftProgram == nil || leftProgram is VROneDistortionProgram {
                leftProgram = CardboardDistortionProgram(params: headset, screen: screen, eye: Eye.left)
                rightProgram = CardboardDistortionProgram(params: headset, screen: screen, eye: Eye.right)
            } else {
                leftProgram.setParameters(headset, screen: screen, eye: .left)
                rightProgram.setParameters(headset, screen: screen, eye: .right)
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
        
        separatorLayer.backgroundColor = UIColor.white.cgColor
        separatorLayer.frame = CGRect(x: 50, y: view.frame.height / 2 - 2, width: view.frame.width - 50, height: 4)
        view.layer.addSublayer(separatorLayer)
        
        leftLoadingView.activityIndicatorViewStyle = .whiteLarge
        leftLoadingView.startAnimating()
        leftLoadingView.hidesWhenStopped = true
        leftLoadingView.frame = CGRect(x: view.frame.width / 2 - 20, y: view.frame.height / 4 - 20, width: 40, height: 40)
        view.addSubview(leftLoadingView)
        
        rightLoadingView.activityIndicatorViewStyle = .whiteLarge
        rightLoadingView.startAnimating()
        rightLoadingView.hidesWhenStopped = true
        rightLoadingView.frame = CGRect(x: view.frame.width / 2 - 20, y: view.frame.height * 3 / 4 - 20, width: 40, height: 40)
        view.addSubview(rightLoadingView)
        
        settingsButtonView.frame = CGRect(x: 10, y: view.frame.height / 2 - 11, width: 34, height: 22)
        // TODO
        //settingsButtonView.setTitle(String.iconWithName(.Settings), for: UIControlState())
        settingsButtonView.setBackgroundImage(UIImage(named: "vr_icon"), for: UIControlState())
        settingsButtonView.setTitleColor(.white, for: UIControlState())
        settingsButtonView.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
        // Todo
        //settingsButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        settingsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showGlassesSelection"))
        view.addSubview(settingsButtonView)
        
        if case .landscapeLeft = orientation {
            view.transform = view.transform.rotated(by: CGFloat(M_PI))
        }
        
        if !Defaults[.SessionVRGlassesSelected] {
            showGlassesSelection()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance()?.timeEvent("View.Viewer")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        ScreenService.sharedInstance.max()
        UIApplication.shared.setStatusBarHidden(true, with: UIStatusBarAnimation.none)
        UIApplication.shared.isIdleTimerDisabled = true
        
        tabController!.hideUI()
        
        var popActivated = false // needed when viewer was opened without rotation
        InvertableHeadTrackerRotationSource.InvertableInstance.start()
        RotationService.sharedInstance.rotationEnable()
        
        rotationDisposable = RotationService.sharedInstance.rotationSignal?
            .observeValues { [weak self] orientation in
                switch orientation {
                case .portrait:
                    if popActivated {
                        DispatchQueue.main.async() {
                            self?.navigationController?.popViewController(animated: false)
                        }
                        popActivated = false
                    }
                default:
                    popActivated = true
                }
        }
        
        
        let leftImageCallback = { [weak self] (image: SKTexture, index: CubeImageCache.Index) -> Void in
            DispatchQueue.main.async {
                self?.leftRenderDelegate.setTexture(image, forIndex: index)
                self?.leftLoadingView.stopAnimating()
            }
        }
        
        leftRenderDelegate.nodeEnterScene = { [weak self] index in
            queue.async {
                //print("Left enter.")
                self?.leftCache.get(index, callback: leftImageCallback)
            }
        }
        
        leftRenderDelegate.nodeLeaveScene = { [weak self] index in
            queue.async { [weak self] in
                //print("Left leave.")
                self?.leftCache.forget(index)
            }
        }
        
        let rightImageCallback = { [weak self] (image: SKTexture, index: CubeImageCache.Index) -> Void in
            DispatchQueue.main.async {
                self?.rightRenderDelegate.setTexture(image, forIndex: index)
                self?.rightLoadingView.stopAnimating()
            }
        }
        
        rightRenderDelegate.nodeEnterScene = { [weak self] index in
            queue.async {
                //print("Right enter.")
                self?.rightCache.get(index, callback: rightImageCallback)
            }
        }
        
        rightRenderDelegate.nodeLeaveScene = { [weak self] index in
            queue.async { [weak self] in
                //print("Right leave.")
                self?.rightCache.forget(index)
            }
        }
        
        rightRenderDelegate.requestAll()
        leftRenderDelegate.requestAll()
    }
    
    func setViewerParameters(_ headset: CardboardParams) {
        self.headset = headset
        
        loadDistortionShader()
        applyDistortionShader()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        rotationDisposable?.dispose()
        RotationService.sharedInstance.rotationDisable()
        InvertableHeadTrackerRotationSource.InvertableInstance.stop()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        applyDistortionShader()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        leftCache.dispose()
        rightCache.dispose()
        leftRenderDelegate.dispose()
        rightRenderDelegate.dispose()
        
        tabBarController?.tabBar.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        ScreenService.sharedInstance.reset()
        UIApplication.shared.setStatusBarHidden(false, with: UIStatusBarAnimation.none)
        UIApplication.shared.isIdleTimerDisabled = false
        
        super.viewWillDisappear(animated)
    }
    
    fileprivate static func createScnView(_ frame: CGRect) -> SCNView {
        var scnView: SCNView
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: frame, options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.openGLES2.rawValue])
        } else {
            scnView = SCNView(frame: frame)
        }
        
        scnView.backgroundColor = .black
        scnView.isPlaying = true
        
        return scnView
    }
    
    func showGlassesSelection() {
        glassesSelectionView = GlassesSelectionView()
        glassesSelectionView!.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
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
    
    fileprivate let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        return UIVisualEffectView(effect: blurEffect)
    }()

    fileprivate let cancelButtonView = UIButton()
    fileprivate let titleTextView = UILabel()
    fileprivate let glassesIconView = UILabel()
    fileprivate let glassesTextView = UILabel()
    var qrImageview = UIImageView()
    var vrImageview = UIImageView()
    fileprivate let qrcodeIconView = UILabel()
    fileprivate let qrcodeTextView = UILabel()
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    fileprivate let loadingIndicatorView = UIActivityIndicatorView()
    
    fileprivate var loading: Bool = false
    
    var closeCallback: (() -> ())?
    var paramsCallback: ((CardboardParams) -> ())?
    
    var captureSession: AVCaptureSession?
    var code: String?
    
    var glasses: String? {
        didSet {
            glassesTextView.text = glasses
        }
    }
    
    init () {
        super.init(frame: CGRect.zero)
        
        addSubview(blurView)
        
        // TODO
        //cancelButtonView.setTitle(String.iconWithName(.cancel), for: UIControlState())
        cancelButtonView.setTitleColor(.white, for: UIControlState())
        // TODO
        //cancelButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        cancelButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        addSubview(cancelButtonView)
        
        titleTextView.text = "Choose your VR glasses"
        titleTextView.textColor = .white
        titleTextView.textAlignment = .center
        titleTextView.font = UIFont.displayOfSize(35, withType: .Thin)
        addSubview(titleTextView)
        
        let vrimage: UIImage = UIImage(named: "vr_icon")!
        vrImageview = UIImageView(image: vrimage)
        addSubview(vrImageview)

        glassesIconView.isUserInteractionEnabled = true
        glassesIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        addSubview(glassesIconView)
        
        glassesTextView.font = UIFont.displayOfSize(15, withType: .Semibold)
        glassesTextView.textColor = .white
        glassesTextView.textAlignment = .center
        glassesTextView.isUserInteractionEnabled = true
        glassesTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "cancel"))
        addSubview(glassesTextView)
        
        let qrimage: UIImage = UIImage(named: "qr")!
        qrImageview = UIImageView(image: qrimage)
        addSubview(qrImageview)

        qrcodeIconView.isUserInteractionEnabled = true
        qrcodeIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "scan"))
        addSubview(qrcodeIconView)

        
        qrcodeTextView.font = UIFont.displayOfSize(15, withType: .Semibold)
        qrcodeTextView.textColor = .white
        qrcodeTextView.text = "Scan QR code"
        qrcodeTextView.textAlignment = .center
        qrcodeTextView.isUserInteractionEnabled = true
        qrcodeTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "scan"))
        addSubview(qrcodeTextView)
        
        loadingIndicatorView.activityIndicatorViewStyle = .whiteLarge
        addSubview(loadingIndicatorView)
        
        Mixpanel.sharedInstance()?.track("View.CardboardSelection")
    }
    
    deinit {
        logRetain()
    }
    
    fileprivate func updateLoading(_ loading: Bool) {
        titleTextView.isHidden = loading
        glassesIconView.isHidden = loading
        glassesTextView.isHidden = loading
        qrcodeIconView.isHidden = loading
        qrcodeTextView.isHidden = loading
        previewLayer?.isHidden = loading
        loadingIndicatorView.isHidden = !loading
        
        if loading {
            loadingIndicatorView.startAnimating()
        } else {
            loadingIndicatorView.stopAnimating()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    fileprivate override func layoutSubviews() {
        blurView.frame = bounds
        
        cancelButtonView.frame = CGRect(x: bounds.width - 50, y: 20, width: 30, height: 30)
        
        titleTextView.frame = CGRect(x: 0, y: bounds.height * 0.25 - 19, width: bounds.width, height: 38)
        
        glassesIconView.frame = CGRect(x: bounds.width * 0.37 - 37, y: bounds.height * 0.5 - 12, width: 74, height: 50)
        glassesTextView.frame = CGRect(x: bounds.width * 0.37 - 100, y: bounds.height * 0.5 + 70, width: 200, height: 20)
        
        qrcodeIconView.frame = CGRect(x: bounds.width * 0.63 - 37, y: bounds.height * 0.5 - 25, width: 74, height: 74)
        qrcodeTextView.frame = CGRect(x: bounds.width * 0.63 - 100, y: bounds.height * 0.5 + 70, width: 200, height: 20)
        
        loadingIndicatorView.frame = CGRect(x: bounds.width * 0.5 - 20, y: bounds.height * 0.5 - 20, width: 40, height: 40)

        vrImageview.frame = CGRect(x: bounds.width * 0.37 - 37, y: bounds.height * 0.5 - 12, width: 74, height: 50)
        qrImageview.frame = CGRect(x: bounds.width * 0.63 - 37, y: bounds.height * 0.5 - 25, width: 74, height: 74)

        super.layoutSubviews()
        
    }
    
    fileprivate func setupCamera() {
        captureSession = AVCaptureSession()
        
        let videoCaptureDevice: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        try! videoCaptureDevice.lockForConfiguration()
        videoCaptureDevice.focusMode = .continuousAutoFocus
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
            
            let queue = DispatchQueue(label: "qr_scan_queue", attributes: [])
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
    
    dynamic func cancel() {
        captureSession?.stopRunning()
        closeCallback?()
    }
    
    dynamic func scan() {
        setupCamera()
    }
}

extension GlassesSelectionView: AVCaptureMetadataOutputObjectsDelegate {
    dynamic func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if loading {
            return
        }
        
        for metadata in metadataObjects {
            let readableObject = metadata as! AVMetadataMachineReadableCodeObject
            let code = readableObject.stringValue
            
            if !(code?.isEmpty)! {
                
                loading = true
                captureSession?.stopRunning()
                
                Async.main { [weak self] in
                    self?.updateLoading(true)
                }
                
                let shortUrl = (code?.contains("http://"))! ? code : "http://\(code)"
                
                CardboardParams.fromUrl(shortUrl!) { [weak self] result in
                    
                    switch result {
                    case let .success(params):
                        Async.main {
                            Defaults[.SessionVRGlasses] = params.compressedRepresentation.base64EncodedString()
                            
                            let cardboardDescription = "\(params.vendor) \(params.model)"
                            Mixpanel.sharedInstance()?.track("View.CardboardSelection.Scanned", properties: ["cardboard": cardboardDescription, "url" : shortUrl])
                            Mixpanel.sharedInstance()?.people.set(["Last scanned Cardboard": cardboardDescription])
                            self?.paramsCallback?(params)
                            self?.cancel()
                        }
                    case let .failure(error):
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

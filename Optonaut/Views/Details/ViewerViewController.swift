import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import CoreGraphics
import Mixpanel
import WebImage
import ReactiveCocoa
import Crashlytics
import GoogleCardboardParser

class ViewerViewController: UIViewController  {
    
    private let orientation: UIInterfaceOrientation
    private let optograph: Optograph
    
    private var leftRenderDelegate: StereoRenderDelegate!
    private var rightRenderDelegate: StereoRenderDelegate!
    private var leftScnView: SCNView!
    private var rightScnView: SCNView!
    private let separatorLayer = CALayer()
    private let headset: CardboardParams
    private let screen: ScreenParams
    
    private var rotationDisposable: Disposable?
    private var leftDownloadDisposable: Disposable?
    private var rightDownloadDisposable: Disposable?
    
    required init(orientation: UIInterfaceOrientation, optograph: Optograph) {
        self.orientation = orientation
        self.optograph = optograph
        
        
        screen = ScreenParams.iPhone5
        // Default cardboard
        //headset = CardboardParams()
        
        // VRO
        // headset = CardboardFactory.Ca rdboardParamsFromBase64("Cg1DYXJsIFplaXNzIEFHEgZWUiBPTkUdUI0XPSW28309KhAAAEhCAABIQgAASEIAAEhCWAE1KVwPPToIzczMPQAAgD9QAGAA")
        // 1+1
        
        headset = CardboardFactory.CardboardParamsFromBase64("CgZHb29nbGUSEkNhcmRib2FyZCBJL08gMjAxNR2ZuxY9JbbzfT0qEAAASEIAAEhCAABIQgAASEJYADUpXA89OgiCc4Y-MCqJPlAAYAM=")
        
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
        
        if headset.leftEyeMaxFov.left != headset.leftEyeMaxFov.right {
            Answers.logCustomEventWithName("Error", customAttributes: ["type": "viewer", "error": "Got cardboard viewer with assymetric FOV. Please implement custom frustum."])
        }
        
        let fov: Double = Double(headset.leftEyeMaxFov.left) * Double(2)
        
        leftRenderDelegate = StereoRenderDelegate(rotationMatrixSource: HeadTrackerRotationSource.Instance, width: leftScnView.frame.width, height: leftScnView.frame.height, fov: fov)
        rightRenderDelegate = StereoRenderDelegate(rotationMatrixSource: HeadTrackerRotationSource.Instance, width: rightScnView.frame.width, height: rightScnView.frame.height, fov: fov)
        
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

        
        let leftProgram = DistortionProgram(params: headset, screen: screen, eye: Eye.Left)
        let rightProgram = DistortionProgram(params: headset, screen: screen, eye: Eye.Right)
        
        leftScnView.technique = leftProgram.technique
        rightScnView.technique = rightProgram.technique
        
        //switch SessionService.sessionData!.vrGlasses {
        //case .GoogleCardboard:
        //    leftScnView.technique = createDistortionTechnique("barrell_displacement")
        //    rightScnView.technique = createDistortionTechnique("barrell_displacement")
        //case .VROne:
        //    leftScnView.technique = createDistortionTechnique("zeiss_displacement_left")
        //    rightScnView.technique = createDistortionTechnique("zeiss_displacement_right")
        //default:
        //    leftScnView.technique = createDistortionTechnique("barrell_displacement")
        //    rightScnView.technique = createDistortionTechnique("barrell_displacement")
        //}
        
        view.addSubview(rightScnView)
        view.addSubview(leftScnView)
        
        separatorLayer.backgroundColor = UIColor.whiteColor().CGColor
        separatorLayer.frame = CGRect(x: 0, y: view.frame.height / 2 - 2, width: view.frame.width, height: 4)
        view.layer.addSublayer(separatorLayer)
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
    
    private func createDistortionTechnique(name: String) -> SCNTechnique {
        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(name, ofType: "json")!)
        let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
        let technique = SCNTechnique(dictionary: json as! [String : AnyObject])
        
        return technique!
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
}
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
    private var headset: CardboardParams!
    private var screen: ScreenParams!
    
    private var leftProgram: DistortionProgram!
    private var rightProgram: DistortionProgram!
    
    private var rotationDisposable: Disposable?
    private var leftDownloadDisposable: Disposable?
    private var rightDownloadDisposable: Disposable?
    
    required init(orientation: UIInterfaceOrientation, optograph: Optograph) {
        self.orientation = orientation
        self.optograph = optograph
        
        
        // Please set this to meaningful default values.
        screen = ScreenParams.iPhone6
        headset = CardboardParams()
        
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
    
    func setViewerParameters(headset: CardboardParams, screen: ScreenParams) {
        self.headset = headset
        self.screen = screen
        
        self.leftProgram.setParameters(headset, screen: screen, eye: Eye.Left)
        self.rightProgram.setParameters(headset, screen: screen, eye: Eye.Right)
        
        self.leftRenderDelegate.fov = self.leftProgram.fov
        self.rightRenderDelegate.fov = self.rightProgram.fov
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
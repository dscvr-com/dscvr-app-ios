import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import CoreGraphics
import Mixpanel
import WebImage
import ReactiveCocoa

protocol RotationMatrixSource {
    func getRotationMatrix() -> GLKMatrix4
}

class ViewerViewController: UIViewController  {

    enum Distortion {
        case None, VROne, Barrell
    }
    
    private let orientation: UIInterfaceOrientation
    private let optograph: Optograph
    private let distortion: Distortion
    
    private var originalBrightness: CGFloat!
    
    private var leftRenderDelegate: StereoRenderDelegate!
    private var rightRenderDelegate: StereoRenderDelegate!
    private var leftScnView: SCNView!
    private var rightScnView: SCNView!
    
    required init(orientation: UIInterfaceOrientation, optograph: Optograph, distortion: Distortion) {
        self.orientation = orientation
        self.optograph = optograph
        self.distortion = distortion
        
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
        
        leftRenderDelegate = StereoRenderDelegate(rotationMatrixSource: MotionService.sharedInstance, width: leftScnView.frame.width, height: leftScnView.frame.height, fov: 85)
        rightRenderDelegate = StereoRenderDelegate(rotationMatrixSource: MotionService.sharedInstance, width: rightScnView.frame.width, height: rightScnView.frame.height, fov: 85)
        
        SDWebImageManager.sharedManager().downloadImageForURL(optograph.leftTextureAssetURL)
            .startWithNext { [weak self] image in self?.leftRenderDelegate.image = image }
        SDWebImageManager.sharedManager().downloadImageForURL(optograph.rightTextureAssetURL)
            .startWithNext { [weak self] image in self?.rightRenderDelegate.image = image }
            
        leftScnView.scene = leftRenderDelegate.scene
        leftScnView.delegate = leftRenderDelegate
        
        rightScnView.scene = rightRenderDelegate.scene
        rightScnView.delegate = rightRenderDelegate
        
        switch distortion {
        case .Barrell:
            leftScnView.technique = createDistortionTechnique("barrell_displacement")
            rightScnView.technique = createDistortionTechnique("barrell_displacement")
        case .VROne:
            leftScnView.technique = createDistortionTechnique("zeiss_displacement_left")
            rightScnView.technique = createDistortionTechnique("zeiss_displacement_right")
        default: break
        }
        
        view.addSubview(rightScnView)
        view.addSubview(leftScnView)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.Viewer")

        tabBarController?.tabBar.hidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        originalBrightness = UIScreen.mainScreen().brightness
        UIScreen.mainScreen().brightness = 1
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        MotionService.sharedInstance.motionFast()
        MotionService.sharedInstance.rotateEnable { [weak self] orientation in
            if case .Portrait = orientation {
                print("pop viewer")
                self?.navigationController?.popViewControllerAnimated(false)
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        MotionService.sharedInstance.motionSlow()
        MotionService.sharedInstance.rotateDisable()
        
        Mixpanel.sharedInstance().track("View.Viewer", properties: ["optograph_id": optograph.id])
    }
    
    override func viewWillDisappear(animated: Bool) {
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIScreen.mainScreen().brightness = originalBrightness
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = false
        
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
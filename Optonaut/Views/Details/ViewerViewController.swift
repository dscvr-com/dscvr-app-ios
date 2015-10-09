import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import CoreGraphics
import Mixpanel

protocol RotationMatrixSource {
    func getRotationMatrix() -> CMRotationMatrix?
}

extension CMMotionManager: RotationMatrixSource {
    func getRotationMatrix() -> CMRotationMatrix? {
        return deviceMotion?.attitude.rotationMatrix
    }
}

class ViewerViewController: UIViewController  {

    enum Distortion {
        case None, VROne, Barrell
    }
    
    private let orientation: UIInterfaceOrientation
    private let optograph: Optograph
    private let distortion: Distortion
    
    private let motionManager = CMMotionManager()
    
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
    
    private func createScnView(frame: CGRect) -> SCNView {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let width = view.frame.width
        let height = view.frame.height
        
        leftScnView = createScnView(CGRect(x: 0, y: 0, width: width, height: height / 2))
        rightScnView = createScnView(CGRect(x: 0, y: height / 2, width: width, height: height / 2))
        
        leftRenderDelegate = StereoRenderDelegate(eye: .Left, optograph: optograph, rotationMatrixSource: motionManager, width: leftScnView.frame.width, height: leftScnView.frame.height)
        rightRenderDelegate = StereoRenderDelegate(eye: .Right, optograph: optograph, rotationMatrixSource: motionManager, width: rightScnView.frame.width, height: rightScnView.frame.height)
            
        leftScnView.scene = leftRenderDelegate.root
        leftScnView.delegate = leftRenderDelegate
        
        rightScnView.scene = rightRenderDelegate.root
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
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60
        motionManager.startDeviceMotionUpdates()
        
        var popActivated = false // needed when viewer was opened without rotation
        motionManager.accelerometerUpdateInterval = 0.3
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { accelerometerData, error in
            if let accelerometerData = accelerometerData {
                let x = accelerometerData.acceleration.x
                let y = accelerometerData.acceleration.y
                if !popActivated && -x > abs(y) + 0.5 {
                    popActivated = true
                }
                if (popActivated && abs(y) > -x + 0.5) || x > abs(y) {
                    self.navigationController?.popViewControllerAnimated(false)
                }
            }
        })
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
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        
        Mixpanel.sharedInstance().track("View.Viewer", properties: ["optograph_id": optograph.id])
    }
    
    override func viewWillDisappear(animated: Bool) {
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIScreen.mainScreen().brightness = originalBrightness
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        leftScnView.playing = false
        rightScnView.playing = false
        
        leftRenderDelegate.dispose()
        rightRenderDelegate.dispose()
        
        super.viewWillDisappear(animated)
    }
    
    private func createDistortionTechnique(name: String) -> SCNTechnique {
        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(name, ofType: "json")!)
        let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
        let technique = SCNTechnique(dictionary: json as! [String : AnyObject])
        
        return technique!
    }
}

class StereoRenderDelegate: NSObject, SCNSceneRendererDelegate {
    
    enum Eye {
        case Left, Right
    }
    
    let optograph: Optograph
    let cameraNode: SCNNode
    let sphereNode: SCNNode
    let rotationMatrixSource: RotationMatrixSource
    let eye: Eye
    let image: UIImage
    let root = SCNScene()
    
    init(eye: Eye, optograph: Optograph, rotationMatrixSource: RotationMatrixSource, width: CGFloat, height: CGFloat) {
        self.optograph = optograph
        self.rotationMatrixSource = rotationMatrixSource
        self.eye = eye
        
        let camera = SCNCamera()
        let fov = 85 as Double
        camera.zNear = 0.01
        camera.zFar = 10000
        camera.xFov = fov
        camera.yFov = fov * Double(width / height)
        
        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        root.rootNode.addChildNode(cameraNode)
        
        switch eye {
        case .Left: image = UIImage(data: NSData(contentsOfFile: "\(StaticPath)/\(optograph.leftTextureAssetId).jpg")!)!
        case .Right: image = UIImage(data: NSData(contentsOfFile: "\(StaticPath)/\(optograph.rightTextureAssetId).jpg")!)!
        }
        
        sphereNode = StereoRenderDelegate.createSphere(image)
        root.rootNode.addChildNode(sphereNode)
        
        super.init()
    }
    
    func dispose() {
        sphereNode.removeFromParentNode()
        cameraNode.removeFromParentNode()
    }

    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        if let r = rotationMatrixSource.getRotationMatrix() {
            cameraNode.transform = SCNMatrix4FromGLKMatrix4(GLKMatrix4Make(
                Float(r.m11), Float(r.m12), Float(r.m13), 0,
                Float(r.m21), Float(r.m22), Float(r.m23), 0,
                Float(r.m31), Float(r.m32), Float(r.m33), 0,
                0,            0,            0,            1
                )
            )
        }
    }
    
    private static func createSphere(image: UIImage?) -> SCNNode {
        // rotate sphere to correctly display texture
        let transform = SCNMatrix4Scale(SCNMatrix4MakeRotation(Float(M_PI_2), 1, 0, 0), -1, 1, 1)
        
        let geometry = SCNSphere(radius: 5.0)
        geometry.segmentCount = 128
        geometry.firstMaterial?.diffuse.contents = image!
        geometry.firstMaterial?.doubleSided = true
        
        let node = SCNNode(geometry: geometry)
        node.transform = transform
        
        return node
    }
    
    private static func createPlane(image: UIImage?) -> SCNNode {
        let planeGeometry = SCNPlane(width: 10, height: 10)
        planeGeometry.firstMaterial?.diffuse.contents = image
        
        return SCNNode(geometry: planeGeometry)
    }
    
}
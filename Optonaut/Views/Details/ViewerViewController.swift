import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import CoreGraphics

class ViewerViewController: UIViewController  {
    
    let orientation: UIInterfaceOrientation
    let optograph: Optograph
    
    let motionManager = CMMotionManager()
    
    let leftCameraNode = SCNNode()
    let rightCameraNode = SCNNode()
    
    var originalBrightness: CGFloat!
    var enableDistortion = false
    
    required init(orientation: UIInterfaceOrientation, optograph: Optograph) {
        self.orientation = orientation
        self.optograph = optograph
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftScene = SCNScene()
        let rightScene = SCNScene()
        
        let camera = SCNCamera()
        let fov = 65 as Double
        camera.zNear = 0.01
        camera.zFar = 10000
        camera.xFov = fov
        camera.yFov = fov * Double(view.bounds.width / 2 / view.bounds.height)
        
        leftCameraNode.camera = camera
        leftCameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        leftScene.rootNode.addChildNode(leftCameraNode)
        
        rightCameraNode.camera = camera
        rightCameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        rightScene.rootNode.addChildNode(rightCameraNode)
        
        let leftUrl = NSURL(string: "http://optonaut-ios-beta-dev.s3.amazonaws.com/optographs/original/\(optograph.id)/left.jpg")!
        let leftData = NSData(contentsOfURL: leftUrl)!
        let leftSphereGeometry = SCNSphere(radius: 5.0)
        leftSphereGeometry.firstMaterial?.diffuse.contents = UIImage(data: leftData)
        leftSphereGeometry.firstMaterial?.doubleSided = true
        let leftSphereNode = SCNNode(geometry: leftSphereGeometry)
        leftSphereNode.transform = SCNMatrix4MakeRotation(Float(M_PI_2), 1, 0, 0)
        leftScene.rootNode.addChildNode(leftSphereNode)
        
        let rightUrl = NSURL(string: "http://optonaut-ios-beta-dev.s3.amazonaws.com/optographs/original/\(optograph.id)/right.jpg")!
        let rightData = NSData(contentsOfURL: rightUrl)!
        let rightSphereGeometry = SCNSphere(radius: 5.0)
        rightSphereGeometry.firstMaterial?.diffuse.contents = UIImage(data: rightData)
        rightSphereGeometry.firstMaterial?.doubleSided = true
        let rightSphereNode = SCNNode(geometry: rightSphereGeometry)
        rightSphereNode.transform = SCNMatrix4MakeRotation(Float(M_PI_2), 1, 0, 0)
        rightScene.rootNode.addChildNode(rightSphereNode)
        
        let width = view.bounds.width
        let height = view.bounds.height
        
        let leftScnView = SCNView()
        leftScnView.frame = CGRect(x: 0, y: 0, width: width, height: height / 2)
        
        leftScnView.backgroundColor = .blackColor()
        leftScnView.scene = leftScene
        leftScnView.playing = true
        leftScnView.delegate = self
        
        if enableDistortion {
//            leftScnView.technique = createDistortionTechnique("displacement_left")
        }
        view.addSubview(leftScnView)
        
        let rightScnView = SCNView()
        rightScnView.frame = CGRect(x: 0, y: height / 2, width: width, height: height / 2)
        
        rightScnView.backgroundColor = .blackColor()
        rightScnView.scene = rightScene
        rightScnView.playing = true
        rightScnView.delegate = self
        
        if enableDistortion {
//            rightScnView.technique = createDistortionTechnique("displacement_right")
        }
        
        view.addSubview(rightScnView)
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates()
        
        var popActivated = false // needed when viewer was opened without rotation
        motionManager.accelerometerUpdateInterval = 0.3
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { accelerometerData, error in
            if let accelerometerData = accelerometerData {
                let x = accelerometerData.acceleration.x
                let y = accelerometerData.acceleration.y
                if !popActivated && abs(x) > abs(y) + 0.5 {
                    popActivated = true
                }
                if popActivated && abs(y) > abs(x) + 0.5 {
                    self.navigationController?.popViewControllerAnimated(false)
                }
            }
        })
    }
    
//    func createDistortionTechnique(name: String) -> SCNTechnique {
//        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(name, ofType: "json")!)
//        let json = NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
//        let technique = SCNTechnique(dictionary: json as [NSObject : AnyObject])
//        
//        return technique!
//    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.tabBar.hidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        originalBrightness = UIScreen.mainScreen().brightness
        UIScreen.mainScreen().brightness = 1
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIScreen.mainScreen().brightness = originalBrightness
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        
        super.viewWillDisappear(animated)
    }
    
}

// MARK: - SCNSceneRendererDelegate
extension ViewerViewController: SCNSceneRendererDelegate {
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        if let motion = self.motionManager.deviceMotion {
            let r = motion.attitude.rotationMatrix
            
            let transform = SCNMatrix4FromGLKMatrix4(GLKMatrix4Make(
                Float(r.m11), Float(r.m12), Float(r.m13), 0,
                Float(r.m21), Float(r.m22), Float(r.m23), 0,
                Float(r.m31), Float(r.m32), Float(r.m33), 0,
                0,            0,            0,            1))
            
            self.leftCameraNode.transform = transform
            self.rightCameraNode.transform = transform
        }
    }
    
}

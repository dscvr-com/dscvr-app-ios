import UIKit
import QuartzCore
import SceneKit
import SwiftyJSON
import CoreMotion
import CoreGraphics

class SphereViewController: UIViewController  {
    
    let motionManager = CMMotionManager()
    let focalLength: Float = -1.0
    var leftCameraNode: SCNNode!
    var rightCameraNode: SCNNode!
    var dummy: SCNNode!
    var leftScnView: SCNView!
    var rightScnView: SCNView!
    var leftScene: SCNScene!
    var rightScene: SCNScene!
    
    var originalBrightness: CGFloat!
    var enableDistortion = false
    
    var leftEyeOffset: GLKMatrix4!
    var rightEyeOffset: GLKMatrix4!
    var m: SCNMatrix4!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftScene = SCNScene()
        rightScene = SCNScene()
        
        //        leftEyeOffset = GLKMatrix4MakeRotation(Float(M_PI) / -40, 0, 1, 0)
        leftEyeOffset = GLKMatrix4Identity
        rightEyeOffset = GLKMatrix4Invert(leftEyeOffset, nil)
        
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 10000
        
        camera.xFov = 65
        camera.yFov = 65 * Double(view.bounds.width / 2 / view.bounds.height)
        var mMatrixValues: [Float] = [0, 1, 0, 0,
                            -1, 0, 0, 0,
                            0, 0, 1, 0,
                            0, 0, 0, 1]
        
        m = SCNMatrix4FromGLKMatrix4(GLKMatrix4MakeWithArray(&mMatrixValues))
        //let m = SCNMatrix4FromGLKMatrix4(GLKMatrix4MakeRotation(Float(M_PI_2), 0, 0, 1))
        
        //var proj = camera.projectionTransform()
        //proj = SCNMatrix4Mult(m, proj)
        //camera.setProjectionTransform(proj);
        
        leftCameraNode = SCNNode()
        leftCameraNode.camera = camera
        leftCameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        leftScene.rootNode.addChildNode(leftCameraNode)
        
        rightCameraNode = SCNNode()
        rightCameraNode.camera = camera
        rightCameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        rightScene.rootNode.addChildNode(rightCameraNode)
        
        dummy = SCNNode()
        
        
        let leftSphereGeometry = SCNSphere(radius: 5.0)
        leftSphereGeometry.firstMaterial?.diffuse.contents = UIImage(named: "left_large")
        leftSphereGeometry.firstMaterial?.doubleSided = true
        let leftSphereNode = SCNNode(geometry: leftSphereGeometry)
        //leftSphereNode.transform = SCNMatrix4FromGLKMatrix4(m)
        leftScene.rootNode.addChildNode(leftSphereNode)
        
        let rightSphereGeometry = SCNSphere(radius: 5.0)
        rightSphereGeometry.firstMaterial?.diffuse.contents = UIImage(named: "right_large")
        rightSphereGeometry.firstMaterial?.doubleSided = true
        let rightSphereNode = SCNNode(geometry: rightSphereGeometry)
        //rightSphereNode.transform = SCNMatrix4FromGLKMatrix4(m)
        rightScene.rootNode.addChildNode(rightSphereNode)
        
        
        let width = view.bounds.width
        let height = view.bounds.height
        
        leftScnView = SCNView(frame: CGRect(x: 0, y: 0, width: width, height: height / 2))
        
        leftScnView.backgroundColor = .blackColor()
        leftScnView.scene = leftScene
        leftScnView.playing = true
        leftScnView.delegate = self
        
        if enableDistortion {
            leftScnView.technique = createDistortionTechnique("displacement_left")
        }
        view.addSubview(leftScnView)
        
        rightScnView = SCNView(frame: CGRect(x: 0, y: height / 2, width: width, height: height / 2))
        
        rightScnView.backgroundColor = .blackColor()
        rightScnView.scene = rightScene
        rightScnView.playing = true
        rightScnView.delegate = self
        
        if enableDistortion {
            rightScnView.technique = createDistortionTechnique("displacement_right")
        }
        
        view.addSubview(rightScnView)
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates()
        
        motionManager.gyroUpdateInterval = 0.3
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: { accelerometerData, error in
            if abs(accelerometerData.acceleration.y) >= 0.75 {
                self.motionManager.stopAccelerometerUpdates()
                self.navigationController?.popViewControllerAnimated(false)
            }
        })
    }
    
    func createDistortionTechnique(name: String) -> SCNTechnique {
        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(name, ofType: "json")!)
        let json = NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers, error: nil) as! NSDictionary
        let technique = SCNTechnique(dictionary: json as [NSObject : AnyObject])
        
        return technique!
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.tabBar.hidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        originalBrightness = UIScreen.mainScreen().brightness
        UIScreen.mainScreen().brightness = 1
    }
    
    override func viewWillDisappear(animated: Bool) {
        tabBarController?.tabBar.hidden = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIScreen.mainScreen().brightness = originalBrightness
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        
        super.viewWillDisappear(animated)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
}

// MARK: - SCNSceneRendererDelegate
extension SphereViewController: SCNSceneRendererDelegate {
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        if let motion = motionManager.deviceMotion {
            let x = -Float(motion.attitude.roll) - Float(M_PI_2)
            let y = Float(motion.attitude.yaw)
            let z = -Float(motion.attitude.pitch)
            dummy.transform = SCNMatrix4Identity
            dummy.eulerAngles.x = x
            dummy.eulerAngles.y = y
            dummy.eulerAngles.z = z
            
            var trans = dummy.transform
            trans = SCNMatrix4Mult(m, trans)
            leftCameraNode.transform = trans
            rightCameraNode.transform = trans
        }
    }
    
}

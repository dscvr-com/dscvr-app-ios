import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import CoreGraphics
import Crashlytics

class ViewerViewController: UIViewController  {
    
    let orientation: UIInterfaceOrientation
    let optograph: Optograph
    
    let motionManager = CMMotionManager()
    
    let leftCameraNode = SCNNode()
    let rightCameraNode = SCNNode()
    
    var leftImage: UIImage?
    var rightImage: UIImage?
    
    var leftSphereNode: SCNNode?
    var rightSphereNode: SCNNode?
    
    var leftScene: SCNScene?
    var rightScene: SCNScene?
    
    var originalBrightness: CGFloat!
    var enableDistortion = false
    
    let showCalibration: Bool
    
    var leftCalibrationText: SCNNode?
    var rightCalibrationText: SCNNode?
    
    var leftRenderDelegate: StereoRenderDelegate?
    var rightRenderDelegate: StereoRenderDelegate?
    
    var angularOffset = 0.0
    
    required init(orientation: UIInterfaceOrientation, optograph: Optograph, showCalibration: Bool) {
        
        Answers.logContentViewWithName("Optograph Viewer \(optograph.id)",
            contentType: "OptographViewer",
            contentId: "optograph-viewer-\(optograph.id)",
            customAttributes: [:])
        
        self.orientation = orientation
        self.optograph = optograph
        self.showCalibration = showCalibration
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createSphere(image: UIImage?) -> SCNNode {
        
        let transform = SCNMatrix4Scale(SCNMatrix4MakeRotation(Float(M_PI_2), 1, 0, 0), -1, 1, 1)
        
        let geometry = SCNSphere(radius: 5.0)
        geometry.segmentCount = 128
        geometry.firstMaterial?.diffuse.contents = image!
        geometry.firstMaterial?.doubleSided = true
        let node = SCNNode(geometry: geometry)
        node.transform = transform
        
        return node
    }
    
    func createTextNode(text: String) -> SCNNode {
        
        let textGeometry = SCNText(string: text, extrusionDepth: 0.001)
        
        textGeometry.font = UIFont.displayOfSize(0.3, withType: .Thin)
        textGeometry.flatness = 0.0005
        textGeometry.firstMaterial?.diffuse.contents = UIColor.blueColor()
        
        let textNode = SCNNode(geometry: textGeometry)
        return textNode
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftScene = SCNScene()
        rightScene = SCNScene()
        
        let camera = SCNCamera()
        let fov = 105 as Double
        camera.zNear = 0.01
        camera.zFar = 10000
        camera.xFov = fov
        camera.yFov = fov * Double(view.bounds.width / 2 / view.bounds.height)
        
        leftCameraNode.camera = camera
        leftCameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        leftScene!.rootNode.addChildNode(leftCameraNode)
        
        rightCameraNode.camera = camera
        rightCameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        rightScene!.rootNode.addChildNode(rightCameraNode)
        
        if showCalibration {
            leftImage = UIImage(named: "calibration")
            rightImage = leftImage
        } else {
            leftImage = UIImage(data: NSData(contentsOfFile: "\(StaticPath)/\(optograph.leftTextureAssetId).jpg")!)
            rightImage = UIImage(data: NSData(contentsOfFile: "\(StaticPath)/\(optograph.rightTextureAssetId).jpg")!)
        }
        
        leftSphereNode = createSphere(leftImage)
        leftScene!.rootNode.addChildNode(leftSphereNode!)
        
        rightSphereNode = createSphere(rightImage)
        rightScene!.rootNode.addChildNode(rightSphereNode!)
        
        if showCalibration {
           // leftCalibrationText = createTextNode("")
           // rightCalibrationText = createTextNode("")
            
           // leftScene!.rootNode.addChildNode(leftCalibrationText!)
           // rightScene!.rootNode.addChildNode(rightCalibrationText!)
        }
        
        let width = view.bounds.width
        let height = view.bounds.height
        
        let leftScnView = SCNView()
        leftScnView.frame = CGRect(x: 0, y: 0, width: width, height: height / 2)
        
        leftRenderDelegate = StereoRenderDelegate(isLeft: true, textNode: leftCalibrationText, cameraNode: leftCameraNode, motionManager: motionManager)
        
        leftScnView.backgroundColor = .blackColor()
        leftScnView.scene = leftScene
        leftScnView.playing = true
        leftScnView.delegate = leftRenderDelegate
        
        if enableDistortion {
            leftScnView.technique = createDistortionTechnique("displacement_left")
        }
        view.addSubview(leftScnView)
        
        let rightScnView = SCNView()
        rightScnView.frame = CGRect(x: 0, y: height / 2, width: width, height: height / 2)
        
        rightRenderDelegate = StereoRenderDelegate(isLeft: false, textNode: rightCalibrationText, cameraNode: rightCameraNode, motionManager: motionManager)
        
        rightScnView.backgroundColor = .blackColor()
        rightScnView.scene = rightScene
        rightScnView.playing = true
        rightScnView.delegate = rightRenderDelegate
        
        if enableDistortion {
            rightScnView.technique = createDistortionTechnique("displacement_right")
        }
        
        view.addSubview(rightScnView)
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 200.0 // MOAR UPDATE SPEED!
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
    
    func createDistortionTechnique(name: String) -> SCNTechnique {
        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource(name, ofType: "json")!)
        let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
        let technique = SCNTechnique(dictionary: json as! [String : AnyObject])
        
        return technique!
    }
    
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
        
        leftImage = nil
        rightImage = nil
        
        leftSphereNode!.removeFromParentNode()
        rightSphereNode!.removeFromParentNode()
        
        leftSphereNode = nil
        rightSphereNode = nil
        
        super.viewWillDisappear(animated)
    }
    
}


class StereoRenderDelegate: NSObject, SCNSceneRendererDelegate {
    
    let textNode: SCNNode?
    let cameraNode: SCNNode
    let motionManager: CMMotionManager
    var angularOffset = 0.0
    let isLeft: Bool
    
    init(isLeft: Bool, sphereNode: SCNNode?, cameraNode: SCNNode, motionManager: CMMotionManager) {
        self.textNode = textNode
        self.cameraNode = cameraNode
        self.motionManager = motionManager
        self.isLeft = isLeft
        
        super.init()
    }
    
    func centerSCNText(text: SCNNode) {
        
        var v1 = SCNVector3(x: 0,y: 0,z: 0)
        var v2 = SCNVector3(x: 0,y: 0,z: 0)
        
        text.getBoundingBoxMin(&v1, max: &v2)
        
        let dx:Float = Float(v1.x - v2.x)/2.0
        let dy:Float = Float(v1.y - v2.y)
        text.pivot = SCNMatrix4MakeTranslation(-dx, -dy, 0)
    }

    
    func updateTextNode() {
        
        let text = String(format: "%.2f", angularOffset * 360 / M_PI)
        (textNode!.geometry as! SCNText).string = text
        
        let transform = textNode!.transform
        textNode!.transform = SCNMatrix4Identity
        centerSCNText(textNode!)
        
        textNode!.transform = transform
    }
    
    func createTextNodeTransform(sceneRotation: SCNMatrix4) -> SCNMatrix4 {
        let translation = SCNMatrix4MakeTranslation(0, 0, -1)
        let rotation = SCNMatrix4MakeRotation(Float(M_PI_2), 0, 0, -1)
        let transform = SCNMatrix4Mult(rotation, translation)
        return SCNMatrix4Mult(transform, sceneRotation)
    }

    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        
        if let motion = motionManager.deviceMotion {
            let r = motion.attitude.rotationMatrix
            
            let transform = SCNMatrix4FromGLKMatrix4(GLKMatrix4Make(
                Float(r.m11), Float(r.m12), Float(r.m13), 0,
                Float(r.m21), Float(r.m22), Float(r.m23), 0,
                Float(r.m31), Float(r.m32), Float(r.m33), 0,
                0,            0,            0,            1))
            
            let eyeCorretion = SCNMatrix4MakeRotation(Float(isLeft ? angularOffset : -angularOffset), 0, 0, 1)
            
            cameraNode.transform = SCNMatrix4Mult(transform, eyeCorretion)
            if textNode != nil {
                textNode!.transform = createTextNodeTransform(cameraNode.transform)
            }
        }
        
        var ly = 0.0
        
        if let accellerometer = motionManager.accelerometerData {
        
            if textNode != nil {
                let y = accellerometer.acceleration.z
                if ly != y {
                    if y > 0.2 {
                        angularOffset = angularOffset + abs(y - 0.2) / 500
                        updateTextNode()
                    }
                    if y < -0.2 {
                        angularOffset = angularOffset - abs(y + 0.2) / 500
                        updateTextNode()
                    }
                    ly = y
                }

            }
        }
    }
    
}

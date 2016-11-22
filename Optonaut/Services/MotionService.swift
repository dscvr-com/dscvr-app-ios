//
//  MotionService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/11/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import CoreMotion
import ReactiveCocoa
import Result

protocol RotationMatrixSource {
    func getRotationMatrix() -> GLKMatrix4
}

class HeadTrackerRotationSource : RotationMatrixSource {
    private let headTracker = HeadTracker()
    private var retainCounter = 0
    
    static let Instance = HeadTrackerRotationSource()
    
    func getRotationMatrix() -> GLKMatrix4 {

        if headTracker.isReady() {
            let rot = GLKMatrix4MakeRotation(Float(M_PI_2), 0, -1, 0)
            let base = GLKMatrix4Make(0, 1, 0, 0,
                -1, 0, 0, 0,
                0, 0, 1, 0,
                0, 0, 0, 1)
            let baseInv = GLKMatrix4Transpose(base);
            return GLKMatrix4Multiply(
                GLKMatrix4Multiply(
                    rot,
                    GLKMatrix4Multiply(
                        baseInv,
                        GLKMatrix4Invert(headTracker.lastHeadView(), nil))),
                base)
        } else {
            return GLKMatrix4Make(1, 0, 0, 0,
                0, 0, 1, 0,
                0, 1, 0, 0,
                0, 0, 0, 1)
        }
        

    }
    
    func start() {
        if retainCounter == 0 {
            headTracker.startTracking(.LandscapeRight)
        }
        retainCounter += 1
    }
    
    func stop() {
        retainCounter -= 1
        if retainCounter == 0 {
            headTracker.stopTracking()
        }
        assert(retainCounter >= 0)
    }
}

class InvertableHeadTrackerRotationSource : HeadTrackerRotationSource {
    
    var inverted = false
    
    static let InvertableInstance = InvertableHeadTrackerRotationSource()
    
    override func getRotationMatrix() -> GLKMatrix4 {
        let result = super.getRotationMatrix()
        
        if inverted {
            return GLKMatrix4Scale(result, -1, -1, 1)
        } else {
            return result
        }
        
    }
    
}
class SpinRotationSource  : RotationMatrixSource {
    private var retainCounter = 0
    private var mat = GLKMatrix4MakeXRotation(Float(M_PI_2))
    
    static let Instance = SpinRotationSource()
    
    func getRotationMatrix() -> GLKMatrix4 {
        mat = GLKMatrix4RotateY(mat, -Float(0.02));
        return mat;
    }
    
    func start() {
        if retainCounter == 0 {
        }
        retainCounter += 1
    }
    
    func stop() {
        retainCounter -= 1
        if retainCounter == 0 {
        }
        assert(retainCounter >= 0)
    }
    
}


class CustomRotationMatrixSource : RotationMatrixSource {
    var phi = Float(0)
    var theta = Float(0)
    
    static let Instance = CustomRotationMatrixSource()
    
    private init() { }
    
    func getRotationMatrix() -> GLKMatrix4 {
        
        // Generate some movement - just for debugging.
        
        phi += Float(0.02)
        
        if(phi > Float(M_PI)) {
            if(theta == 0) {
                theta = Float(0.3)
            } else if(theta > 0) {
                theta = Float(-0.3)
            } else if(theta < 0) {
                theta = Float(0)
            }
            
            phi = 0
        }
        
        let base = GLKMatrix4Make(1, 0, 0, 0,
                                  0, 0, 1, 0,
                                  0, -1, 0, 0,
                                  0, 0, 0, 1)
        
        let rotPhi = GLKMatrix4MakeZRotation(phi)
        let rotTheta = GLKMatrix4MakeXRotation(-theta)
        
        let temp = GLKMatrix4Multiply(rotTheta, base)
        return GLKMatrix4Multiply(rotPhi, temp)
    }
    
    func getRotationMatrixMotor(currentPhi: Float , thetaValue: Float) -> GLKMatrix4 {
        
        // Generate some movement - just for debugging.
        
        // phi -= Float(degreeIncr)
        phi = currentPhi
        print("M_PI \(M_PI)  : phi \(phi) : theta \(theta)")
        theta = thetaValue
        
        /*
         if(phi > Float(M_PI)) {
         if(theta == 0) {
         theta = Float(0.3)
         } else if(theta > 0) {
         theta = Float(-0.3)
         } else if(theta < 0) {
         theta = Float(0)
         }
         
         phi = 0
         }
         */
        
        let base = GLKMatrix4Make(1, 0, 0, 0,
                                  0, 0, 1, 0,
                                  0, -1, 0, 0,
                                  0, 0, 0, 1)
        
        let rotPhi = GLKMatrix4MakeZRotation(phi)
        let rotTheta = GLKMatrix4MakeXRotation(-theta)
        
        let temp = GLKMatrix4Multiply(rotTheta, base)
        return GLKMatrix4Multiply(rotPhi, temp)
    }
    
    
    func start() {
        
    }
    
    func stop() {
        
    }
    
}

class CoreMotionRotationSource : RotationMatrixSource {
    private let motionManager = CMMotionManager()
    private var retainCounter = 0
    
    static let Instance = CoreMotionRotationSource()
    
    func getRotationMatrix() -> GLKMatrix4 {
        
        guard let r = motionManager.deviceMotion?.attitude.rotationMatrix else {
            return GLKMatrix4Make(1, 0, 0, 0,
                0, 0, 1, 0,
                0, 1, 0, 0,
                0, 0, 0, 1)
        }
        return GLKMatrix4Make(
            Float(r.m11), Float(r.m12), Float(r.m13), 0,
            Float(r.m21), Float(r.m22), Float(r.m23), 0,
            Float(r.m31), Float(r.m32), Float(r.m33), 0,
            0,            0,            0,            1
        )
    }
    
    func start() {
        if retainCounter == 0 {
            motionManager.deviceMotionUpdateInterval = 1 / 60
            motionManager.startDeviceMotionUpdates()
        }
        retainCounter += 1
    }
    
    func stop() {
        retainCounter -= 1
        if retainCounter == 0 {
            motionManager.stopDeviceMotionUpdates()
        }
        assert(retainCounter >= 0)
    }
    
}

class RotationService {
    
    typealias RotationSignal = Signal<UIInterfaceOrientation, NoError>
    static let sharedInstance = RotationService()
    private let motionManager = CMMotionManager()
    var rotationSignal: RotationSignal?
    private var retainCounter = 0
    
    private init() {}
    
    func rotationEnable() {
        
        if retainCounter == 0 {
            if rotationSignal != nil {
                return
            }
            
            motionManager.accelerometerUpdateInterval = 0.3
            
            let (signal, sink) = RotationSignal.pipe()
            
            rotationSignal = signal
            
            let queue = NSOperationQueue()
            queue.name = "Rotation queue"
            motionManager.startAccelerometerUpdatesToQueue(queue, withHandler: { accelerometerData, error in
                if let accelerometerData = accelerometerData {
                    let x = accelerometerData.acceleration.x
                    let y = accelerometerData.acceleration.y
                    if sqrt(x * x + y * y) > 0.4 { // Motion is unambigous
                        if abs(x) > abs(y) + 0.2 { // Turned enough
                            sink.sendNext(x > 0 ? .LandscapeLeft : .LandscapeRight)
                        } else if abs(y) > abs(x) + 0.2 {
                            sink.sendNext(.Portrait)
                        }
                    }
                }
            })
        }
        retainCounter += 1
    }
    
    func rotationDisable() {
        retainCounter -= 1
        
        if retainCounter == 0 {
            motionManager.stopAccelerometerUpdates()
            rotationSignal = nil
        }
        assert(retainCounter >= 0)
    }
    
}
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

class MotionService: RotationMatrixSource {
    
    typealias RotationSignal = Signal<UIInterfaceOrientation, NoError>
    
    static let sharedInstance = MotionService()
    
    private let motionManager = CMMotionManager()
    
    var rotationSignal: RotationSignal?
    
    private init() {}
    
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
    
    func motionEnable() {
        motionManager.deviceMotionUpdateInterval = 1 / 60
        motionManager.startDeviceMotionUpdates()
    }
    
    func motionDisable() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func rotationEnable() {
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
                if -x > abs(y) + 0.5 {
                    sendNext(sink, x > 0 ? .LandscapeLeft : .LandscapeRight)
                } else if abs(y) > -x + 0.5 {
                    sendNext(sink, .Portrait)
                }
            }
        })
    }
    
    func rotationDisable() {
        motionManager.stopAccelerometerUpdates()
        rotationSignal = nil
    }
    
}
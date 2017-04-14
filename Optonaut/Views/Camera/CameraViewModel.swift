//
//  CameraViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/15/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveSwift

class CameraViewModel {
    
    let instruction = MutableProperty<String>("")
    let isRecording = MutableProperty<Bool>(false)
    let isCentered = MutableProperty<Bool>(false)
    let progress = MutableProperty<Float>(0)
    let tiltAngle = MutableProperty<Float>(0)
    let distXY = MutableProperty<Float>(0)
    let headingToDot = MutableProperty<Float>(0)
    
    init() {
        isRecording.producer.startWithValues { [unowned self] isRecording in
            if isRecording {
                self.instruction.value = "Follow the orange dot"
            } else {
                self.instruction.value = "Press the button below\r\nto start recording"
            }
        }
        
        distXY.producer.startWithValues { [unowned self] dist in
            self.isCentered.value = dist < 0.11
        }
    }

    deinit {
        logRetain()
    }

}

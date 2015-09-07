//
//  CameraViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/15/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class CameraViewModel {
    
    let instruction = MutableProperty<String>("")
    let isRecording = MutableProperty<Bool>(false)
    let progress = MutableProperty<Float>(0)
    let tiltAngle = MutableProperty<Float>(0)
    
    init() {
        
        isRecording.producer
            .start(next: { isRecording in
                if isRecording {
                    self.instruction.value = "Follow the red dot"
                } else {
                    self.instruction.value = "Press the button\r\nto start recording"
                }
            })
    }
    
}
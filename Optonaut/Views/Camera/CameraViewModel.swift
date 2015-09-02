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
    let debugEnabled: ConstantProperty<Bool>
    let isRecording = MutableProperty<Bool>(false)
    
    init() {
        debugEnabled = ConstantProperty(NSUserDefaults.standardUserDefaults().boolForKey(UserDefaultsKeys.DebugEnabled.rawValue))
    }
    
}
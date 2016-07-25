//
//  BService.swift
//  DSCVR
//
//  Created by BPHi on 22/07/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa


class BService {
    class var sharedInstance: BService {
        struct Static {
            static var instance: BService?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = BService()
        }
        
        return Static.instance!
    }
    var bluetoothData = NSData()
    var dataHasCome = MutableProperty<Bool>(false)
}

//
//  Debouncer.swift
//  Optonaut
//
//  Created by Johannes Schickling on 03/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation

class Debouncer {
    
    private let queue: dispatch_queue_t
    private let delay: Int64
    private var lastFireTime: dispatch_time_t = 0
    
    init(queue: dispatch_queue_t, delay: NSTimeInterval) {
        self.queue = queue
        self.delay = Int64(delay * Double(NSEC_PER_SEC))
    }
    
    func debounce(fn: () -> ()) {
        lastFireTime = dispatch_time(DISPATCH_TIME_NOW, 0)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), queue) {
            let now = dispatch_time(DISPATCH_TIME_NOW, 0)
            let when = dispatch_time(self.lastFireTime, self.delay)
            if now >= when {
                fn()
            }
        }
    }
    
}

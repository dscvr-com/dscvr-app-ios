//
//  Debouncer.swift
//  Optonaut
//
//  Created by Johannes Schickling on 03/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation

class Debouncer {
    
    fileprivate let queue: DispatchQueue
    fileprivate let delay: Int64
    fileprivate var lastFireTime: DispatchTime = DispatchTime.now()
    
    init(queue: DispatchQueue, delay: TimeInterval) {
        self.queue = queue
        self.delay = Int64(delay * Double(NSEC_PER_SEC))
    }
    
    func debounce(_ fn: @escaping () -> ()) {
        lastFireTime = DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC)
        
        queue.asyncAfter(deadline: DispatchTime.now() + Double(delay) / Double(NSEC_PER_SEC)) {
            let now = DispatchTime.now() + Double(0) / Double(NSEC_PER_SEC)
            let when = self.lastFireTime + Double(self.delay) / Double(NSEC_PER_SEC)
            if now >= when {
                fn()
            }
        }
    }
    
}

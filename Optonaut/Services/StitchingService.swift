//
//  StitchingService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/6/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

enum StitchingError: ErrorType {
    case Busy
}

enum StitchingResult {
    case Progress(Float)
    case LeftImage(UIImage)
    case RightImage(UIImage)
}

class StitchingService {
    
    static func startStitching() -> SignalProducer<StitchingResult, StitchingError> {
        return SignalProducer { sink, disposable in
            
            // find best milestone
            
            // stitching in progress
            sendNext(sink, .Progress(0.7))
            sendNext(sink, .Progress(0.8))
            
            // stitching done
            sendNext(sink, .LeftImage(UIImage()))
            sendCompleted(sink)
        }
    }
    
}
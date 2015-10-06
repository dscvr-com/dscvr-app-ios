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
    
    typealias StitcherSignal = SignalProducer<StitchingResult, StitchingError>
    
    private static var activeProcess: StitcherSignal?
    
    /// Returns the currently running stitching process, or
    /// nil, if the stitching service is idle.
    static func getActiveStitchingProcess() -> StitcherSignal {
        return activeProcess
    }
    
    /// This function starts a new stitching process.
    static func startStitching() -> StitcherSignal {
        //Todo - make the stitcher support this.
        activeProcess = SignalProducer { sink, disposable in
            
            // find best milestone
            
            // stitching in progress
            sendNext(sink, .Progress(0.7))
            sendNext(sink, .Progress(0.8))
            
            // stitching done
            sendNext(sink, .LeftImage(UIImage()))
            sendCompleted(sink)
        }
        
        return getActiveSignalProducer()
    }
    
    /// This function resumes a stitching process
    /// that was previously suspended.
    static func resumeStitching() -> StitcherSignal {
        return getActiveSignalProducer()
    }
    
    /// This function is to be called whenever the app is
    /// brought into the foreground. The purpose is to register the 
    /// background handler.
    static func onApplicationResuming()  {
        
    }
    
    //TODO - not sure about this yet.
    static private func cancelStitching() {
    
    }
    
    static private func restoreStitcherState() {
        
    }
    
    static private func suspendStitcher() {
        
    }
}
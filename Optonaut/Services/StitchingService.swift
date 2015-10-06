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
    
    typealias StitchingSignal = Signal<StitchingResult, StitchingError>
    
    private static var activeSignal: StitchingSignal?
    private static var activeSink: (Event<StitchingResult, StitchingError> -> ())?
    
    /// Returns the currently running stitching process, or
    /// nil, if the stitching service is idle.
    static func getStitchingSignal() -> StitchingSignal? {
        return activeSignal
    }
    
    /// This function starts a new stitching process.
    static func startStitching() -> StitchingSignal {
        //Todo - make the stitcher support this.
        
        let (signal, sink) = StitchingSignal.pipe()
        
        activeSignal = signal
        activeSink = sink
        
        // find best milestone
        
        // stitching in progress
        sendNext(sink, .Progress(0.7))
        sendNext(sink, .Progress(0.8))
        
        // stitching done
        sendNext(sink, .LeftImage(UIImage()))
        sendCompleted(sink)
        
        return signal
    }
    
    /// This function resumes a stitching process
    /// that was previously suspended.
    static func resumeStitching() -> StitchingSignal? {
        return getStitchingSignal()
    }
    
    /// This function is to be called whenever the app is
    /// brought into the foreground. The purpose is to register the 
    /// background handler.
    static func onApplicationResuming() {
        
    }
    
    // TODO - not sure about this yet.
    static func cancelStitching() {
        
    }
    
    // TODO: Add interface to start recording and push keyframes
    
    private static func restoreStitcherState() {
        
    }
    
    private static func suspendStitcher() {
        
    }
}
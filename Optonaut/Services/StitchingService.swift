//
//  StitchingService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/6/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Mixpanel
import Async

enum StitchingError: ErrorType {
    case Busy
}

enum StitchingResult {
    case Progress(Float)
    case LeftImage(NSData)
    case RightImage(NSData)
}

enum StitcherError : ErrorType {
    case Cancel
}

class StitchingService {
    
    typealias StitchingSignal = Signal<StitchingResult, StitchingError>
    
    private static var activeSignal: StitchingSignal?
    private static var activeSink: (Event<StitchingResult, StitchingError> -> ())?
    private static let storeRef = Stitcher()
    private static var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private static var shallCancel = false
    
//    /// Returns the currently running stitching process, or
//    /// nil, if the stitching service is idle.
//    static func getStitchingSignal() -> StitchingSignal? {
//        return activeSignal
//    }
    
    static func isStitching() -> Bool {
        return activeSignal != nil
    }
    
    static func canStartRecording() -> Bool {
        return !hasUnstitchedRecordings()
    }
    
    static func hasUnstitchedRecordings() -> Bool {
        return storeRef.hasUnstitchedRecordings()
    }
    
    /// This function starts a new stitching process.
    static func startStitching() -> StitchingSignal {
        if isStitching() {
            return activeSignal!
        }
        
        assert(!isStitching())
        assert(hasUnstitchedRecordings())
        
        shallCancel = false
        
        registerBackgroundTask()
        
        let (signal, sink) = StitchingSignal.pipe()
        
        activeSignal = signal
        activeSink = sink
        
        let priority = DISPATCH_QUEUE_PRIORITY_BACKGROUND
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            Mixpanel.sharedInstance().timeEvent("Action.Camera.Stitching")
            
            let stitcher = Stitcher()
            stitcher.setProgressCallback { progress in
                Async.main {
                    sendNext(sink, .Progress(progress))
                }
                return !shallCancel
            }
            
            if !shallCancel {
                let leftBuffer = stitcher.getLeftResult()
                if !shallCancel {
                    let data = ImageBufferToCompressedUIImage(leftBuffer)
                    sendNext(sink, .LeftImage(data!))
                }
                Recorder.freeImageBuffer(leftBuffer)
            }
            
            if !shallCancel {
                let rightBuffer = stitcher.getRightResult()
                if !shallCancel {
                    let data = ImageBufferToCompressedUIImage(rightBuffer)
                    sendNext(sink, .RightImage(data!))
                }
                Recorder.freeImageBuffer(rightBuffer)
            }
            
            Mixpanel.sharedInstance().track("Action.Camera.Stitching")
            
            
            //Executing this on the main thread is important
            //to avoid a racing condition with onApplicationResuming
            Async.main {
                activeSignal = nil
                activeSink = nil
                unregisterBackgroundTask()
            }
            print("Stitching completed")
            sendCompleted(sink)
        }
        
        return signal
    }
    
    static func removeUnstitchedRecordings() {
        assert(!isStitching())
        if hasUnstitchedRecordings() {
            storeRef.clear()
        }
    }
    
    /// This function is to be called whenever the app is
    /// brought into the foreground. The purpose is to register the 
    /// background handler when we are still stitching.
    static func onApplicationResuming() {
        if isStitching() {
            registerBackgroundTask()
        }
    }
    
    private static func registerBackgroundTask() {
        backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler {
            cancelStitching()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    private static func unregisterBackgroundTask() {
        UIApplication.sharedApplication().endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
    
    // Cancels stitching asynchronously. 
    // send completed is called on termination.
    static func cancelStitching() {
        assert(isStitching())
        print("Stitching cancel called")
        shallCancel = true
    }
}
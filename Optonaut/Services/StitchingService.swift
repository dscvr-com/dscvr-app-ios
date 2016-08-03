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
import AssetsLibrary
import ImageIO

enum StitchingError: ErrorType {
    case Busy
}

enum StitchingResult {
    case Progress(Float)
    case Result(side: TextureSide, face: Int, image: UIImage)
}

enum StitcherError : ErrorType {
    case Cancel
}

class StitchingService {
    
    typealias StitchingSignal = Signal<StitchingResult, StitchingError>
    
    private static var activeSignal: StitchingSignal?
    private static var activeSink: Observer<StitchingResult, StitchingError>?
    private static let storeRef = Stitcher()
    private static var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private static var shallCancel = false
    private static var currentOptograph: UUID?
    
    /// Returns the currently running stitching process, or
    /// nil, if the stitching service is idle.
    static func getStitchingSignal() -> StitchingSignal? {
        return activeSignal
    }
    
    static func getCurrentOptographId() -> UUID? {
        return currentOptograph
    }
    
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
    static func startStitching(optographID: UUID) -> StitchingSignal {
        if isStitching() {
            assert(optographID == currentOptograph)
            return activeSignal!
        }
        
        assert(!isStitching())
        //assert(hasUnstitchedRecordings())
        currentOptograph = optographID
        
        shallCancel = false
        
        let (signal, sink) = StitchingSignal.pipe()
        
        activeSignal = signal
        activeSink = sink
        
        registerBackgroundTask()
        
        let priority = DISPATCH_QUEUE_PRIORITY_BACKGROUND
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            Mixpanel.sharedInstance().track("Action.Stitching.Start")
            Mixpanel.sharedInstance().timeEvent("Action.Stitching.Finish")
            
            let globalAligner = Alignment ()
            
            globalAligner.align()
            
            assert(hasUnstitchedRecordings())
            
            let stitcher = Stitcher()
            stitcher.setProgressCallback { progress in
                Async.main {
                    sink.sendNext(.Progress(progress))
                }
                return !shallCancel
            }
            
            if !shallCancel {
                for (face, cubeFace) in stitcher.getLeftResult().enumerate() {
                    var leftFace = ImageBuffer()
                    cubeFace.getValue(&leftFace)
                    
                    if !shallCancel {
                        autoreleasepool {
                            let image = ImageBufferToCompressedUIImage(leftFace)
                            sink.sendNext(.Result(side: .Left, face: face, image: image))
                        }
                    }
                    Recorder.freeImageBuffer(leftFace)
                }
            }
            
            //get the ER result
            if !shallCancel {
                
                let erImage = stitcher.getLeftEquirectangularResult()
                autoreleasepool {
                    
//                    UIImageWriteToSavedPhotosAlbum(UIImage(CGImage: ImageBufferToCGImage(erImage)), self
//                        , nil, nil)
                    
                    
                    //let asset = ALAssetsLibrary()
                    let image = UIImage(CGImage: ImageBufferToCGImage(erImage))
                    let imageData = UIImageJPEGRepresentation(image, 1.0)
                    
                    let strModel = "RICOH THETA S" as String
                    let strMake = "RICOH" as String
                    
                    let meta:NSDictionary = [kCGImagePropertyTIFFModel as String :strModel,kCGImagePropertyTIFFMake as String:strMake]
//                    meta.setValue(strModel, forKey: kCGImagePropertyTIFFModel as String)
//                    meta.setValue(strMake, forKey: kCGImagePropertyTIFFMake as String)
                    
                    let source:CGImageSourceRef = CGImageSourceCreateWithData(imageData!, nil)!
                    let UTI:CFStringRef = CGImageSourceGetType(source)!
                    
                    let destData = NSMutableData()
                    let destination:CGImageDestinationRef = CGImageDestinationCreateWithData(destData, UTI, 1, nil)!
                    
                    CGImageDestinationAddImageFromSource(destination, source, 0, meta)
                    
                    CGImageDestinationFinalize(destination)
                    
                    UIImageWriteToSavedPhotosAlbum(UIImage(data:destData,scale:1.0)!, self, nil, nil)
                    
//                    asset.writeImageDataToSavedPhotosAlbum(imageData, metadata: meta as [AnyObject : AnyObject], completionBlock: { (path:NSURL!, error:NSError!) -> Void in
//                        print("meta path >>> \(path)")
//                        print("meta error >>> \(error)")
//                    })
                  
                }
                Recorder.freeImageBuffer(erImage)
                
                
            }
            
            if !shallCancel {
                for (face, cubeFace) in stitcher.getRightResult().enumerate() {
                    var rightFace = ImageBuffer()
                    cubeFace.getValue(&rightFace)

                    autoreleasepool {
                        if !shallCancel {
                            let image = ImageBufferToCompressedUIImage(rightFace)
                            sink.sendNext(.Result(side: .Right, face: face, image: image))
                        }
                    }
                    Recorder.freeImageBuffer(rightFace)
                }
            }
            
            Mixpanel.sharedInstance().track("Action.Stitching.Finish")
            
            
            // Executing this on the main thread is important
            // to avoid a racing condition with onApplicationResuming
            Async.main {
                unregisterBackgroundTask()
                activeSignal = nil
                activeSink = nil
                currentOptograph = nil
            }
            
            sink.sendCompleted()
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
        Mixpanel.sharedInstance().track("Action.Stitching.Cancel")
        shallCancel = true
    }
}
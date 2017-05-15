//
//  StitchingService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/6/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveSwift
import Mixpanel
import Async
import ImageIO
import AssetsLibrary
import SwiftyUserDefaults

enum StitchingError: Error {
    case busy
}

enum StitchingResult {
    case progress(Float)
    case result(side: TextureSide, face: Int, image: UIImage)
}

enum StitcherError : Error {
    case cancel
}

class StitchingService {
    
    typealias StitchingSignal = Signal<StitchingResult, StitchingError>
    
    fileprivate static var activeSignal: StitchingSignal?
    fileprivate static var activeSink: Observer<StitchingResult, StitchingError>?
    fileprivate static let storeRef = Stitcher()
    fileprivate static var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    fileprivate static var shallCancel = false
    fileprivate static var currentOptograph: UUID?
    
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
    static func startStitching(_ optographID: UUID) -> StitchingSignal {
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
        
        let priority = DispatchQueue.GlobalQueuePriority.background
        DispatchQueue.global(priority: priority).async {
            
            Mixpanel.sharedInstance()?.track("Action.Stitching.Start")
            Mixpanel.sharedInstance()?.timeEvent("Action.Stitching.Finish")
            
            
            // There is no such thing any more. 
            //assert(hasUnstitchedRecordings())
            
            let stitcher = Stitcher()
            stitcher.setProgressCallback { progress in
                Async.main {
                    sink.send(value: .progress(progress))
                }
                return !shallCancel
            }
            
            if Defaults[.SessionUseMultiRing] {
                if !shallCancel {
                    for (face, cubeFace) in stitcher.getLeftResultThreeRing().enumerated() {
                        var leftFace = ImageBuffer()
                        cubeFace.getValue(&leftFace)
                        
                        if !shallCancel {
                            autoreleasepool {
                                let image = ImageBufferToCompressedUIImage(leftFace)
                                sink.send(value: .result(side: .left, face: face, image: image))
                            }
                        }
                        Recorder.freeImageBuffer(leftFace)
                    }
                }
            
            } else {
                if !shallCancel {
                    for (face, cubeFace) in stitcher.getLeftResult().enumerated() {
                        var leftFace = ImageBuffer()
                        cubeFace.getValue(&leftFace)
                        
                        if !shallCancel {
                            autoreleasepool {
                                let image = ImageBufferToCompressedUIImage(leftFace)
                                sink.send(value: .result(side: .left, face: face, image: image))
                            }
                        }
                        Recorder.freeImageBuffer(leftFace)
                    }
                }
            }
            
            //get the ER result
            if !shallCancel {
                
                var erImage :  ImageBuffer ;
                if Defaults[.SessionUseMultiRing] {
                     erImage = stitcher.getLeftEquirectangularResultThreeRing()
                } else {
                     erImage = stitcher.getLeftEquirectangularResult()
                }
                
                /*
                 // TODO: Save to photo album.
                autoreleasepool {
                    
                    let image = UIImage(cgImage: ImageBufferToCGImage(erImage))
                    let imageData = UIImageJPEGRepresentation(image, 1.0)
                    
                    let asset = ALAssetsLibrary()
                    
                    
                    let strModel: String = "RICOH THETA S"
                    let strMake: String = "RICOH"
                    
                    let tiffData: [String: String] = [kCGImagePropertyTIFFModel as String: strModel,
                                    kCGImagePropertyTIFFMake as String: strMake]
                    
                    asset.writeImageData(toSavedPhotosAlbum: imageData, metadata: tiffData, completionBlock: { (path:URL!, error:NSError!) -> Void in
                        print("meta path >>> \(path)")
                        print("meta error >>> \(error)")
                    })
                    
                }
                */
                Recorder.freeImageBuffer(erImage)
                
                
            }
            if Defaults[.SessionUseMultiRing] {
                if !shallCancel {
                    for (face, cubeFace) in stitcher.getRightResultThreeRing().enumerated() {
                        var rightFace = ImageBuffer()
                        cubeFace.getValue(&rightFace)
                        
                        autoreleasepool {
                            if !shallCancel {
                                let image = ImageBufferToCompressedUIImage(rightFace)
                                sink.send(value: .result(side: .right, face: face, image: image))
                            }
                        }
                        Recorder.freeImageBuffer(rightFace)
                    }
                }
            } else {
                if !shallCancel {
                    for (face, cubeFace) in stitcher.getRightResult().enumerated() {
                        var rightFace = ImageBuffer()
                        cubeFace.getValue(&rightFace)
                        
                        autoreleasepool {
                            if !shallCancel {
                                let image = ImageBufferToCompressedUIImage(rightFace)
                                sink.send(value: .result(side: .right, face: face, image: image))
                            }
                        }
                        Recorder.freeImageBuffer(rightFace)
                    }
                }
            }
            Mixpanel.sharedInstance()?.track("Action.Stitching.Finish")
            
            
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
        if (isStitching()) { //testcode to prevent crash when miscalled
            return
        }
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
    
    fileprivate static func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask (expirationHandler: {
            cancelStitching()
        })
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    fileprivate static func unregisterBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
    
    // Cancels stitching asynchronously. 
    // send completed is called on termination.
    static func cancelStitching() {
        assert(isStitching())
        Mixpanel.sharedInstance()?.track("Action.Stitching.Cancel")
        shallCancel = true
    }
}

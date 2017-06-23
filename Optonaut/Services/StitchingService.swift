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
import CoreImage
import Photos
import MobileCoreServices

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
    static func hasData() -> Bool {
        return storeRef.hasData()
    }
    
    static func saveToPhotoAlbumWithMetadata(_ image: CGImage, _ name: UUID) {
        
        //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/savedMoments/"
        let filePath = path + name + ".jpg"
        try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        
        let cfPath = CFURLCreateWithFileSystemPath(nil, filePath as CFString, CFURLPathStyle.cfurlposixPathStyle, false)
        let destination = CGImageDestinationCreateWithURL(cfPath!, kUTTypeJPEG, 1, nil)
        /*let exifProperties = [
            "ProjectionType": "equirectangular",
            //"UsePanoramaViewer": "TRUE",
            // We need this since our result is a *partial* panorama.
            "FullPanoWidthPixels": "\(image.width)",
            "FullPanoHeightPixels": "\(Int(image.width / 2))",
            "CroppedAreaLeftPixels": "0",
            "CroppedAreaTopPixels": "\(Int((image.width - image.height) / 2))",
            "CroppedAreaImageWidthPixels": "\(image.width)",
            "CroppedAreaImageHeightPixels": "\(image.height)",
        ] as CFDictionary
        */
        
        // This is a hack.
        let tiffProperties = [
            kCGImagePropertyTIFFMake as String: "DSCVR",
            kCGImagePropertyTIFFModel as String: "DSCVR 360"
        ] as CFDictionary
        
        let properties = [
            kCGImagePropertyExifDictionary as String: tiffProperties
        ] as CFDictionary
        
        CGImageDestinationAddImage(destination!, image, properties)
        CGImageDestinationFinalize(destination!)
        
        ExifHelper.addPanoExifData(filePath, Int32(image.width), Int32(image.height))
        
        try? PHPhotoLibrary.shared().performChangesAndWait {
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(fileURLWithPath: filePath))
        }
    }
    
    
    /// This function starts a new stitching process.
    static func startStitching(_ optographID: UUID) -> StitchingSignal {
        if isStitching() {
            assert(optographID == currentOptograph)
            return activeSignal!
        }
        
        assert(!isStitching())
        assert(hasUnstitchedRecordings())
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
            
            let stitcher = Stitcher()
            stitcher.setProgressCallback { progress in
                Async.main {
                    sink.send(value: .progress(progress))
                }
                return !shallCancel
            }

            if !shallCancel {
                autoreleasepool {
                    let buffer = stitcher.getLeftResult()
                    let image = ImageBufferToCGImage(buffer)
                    saveToPhotoAlbumWithMetadata(image, currentOptograph!)
                    for (face, cubeFace) in stitcher.blurAndGetCubeFaces(buffer).enumerated() {
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

            // TODO: Save to photo gallery
            if !shallCancel {
                autoreleasepool {
                    let buffer = stitcher.getRightResult()
                    //let image = ImageBufferToCompressedUIImage(buffer)
                    for (face, cubeFace) in stitcher.blurAndGetCubeFaces(buffer).enumerated() {
                        var rightFace = ImageBuffer()
                        cubeFace.getValue(&rightFace)
                        
                        if !shallCancel {
                            let image = ImageBufferToCompressedUIImage(rightFace)
                            sink.send(value: .result(side: .right, face: face, image: image))
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
        assert(!isStitching())
        if hasData() {
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

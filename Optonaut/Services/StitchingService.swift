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
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/savedMoments/"
        let filePath = path + name + ".jpg"
        try! FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        
        let cfPath = CFURLCreateWithFileSystemPath(nil, filePath as CFString, CFURLPathStyle.cfurlposixPathStyle, false)
        let destination = CGImageDestinationCreateWithURL(cfPath!, kUTTypeJPEG, 1, nil)
        
        let data = CGImageMetadataCreateMutable()
        
        // This writes XMP, we can later use it to add the second image in carboard cam format.
        assert(CGImageMetadataRegisterNamespaceForPrefix(data, "http://ns.google.com/photos/1.0/panorama/" as CFString, "GPano" as CFString, nil))
        
        let fullPanoHeight = Int(image.width / 2)
        
        assert(CGImageMetadataSetValueWithPath(data, nil, "GPano:ProjectionType" as CFString, "equirectangular" as CFString))
        assert(CGImageMetadataSetValueWithPath(data, nil, "GPano:UsePanoramaViewer" as CFString, "TRUE" as CFString))
        assert(CGImageMetadataSetValueWithPath(data, nil, "GPano:FullPanoWidthPixels" as CFString, "\(image.width)" as CFString))
        assert(CGImageMetadataSetValueWithPath(data, nil, "GPano:FullPanoHeightPixels" as CFString, "\(fullPanoHeight)" as CFString))
        assert(CGImageMetadataSetValueWithPath(data, nil, "GPano:CroppedAreaLeftPixels" as CFString, "0" as CFString))
        assert(CGImageMetadataSetValueWithPath(data, nil, "GPano:CroppedAreaTopPixels" as CFString, "\(Int((fullPanoHeight - image.height) / 2))" as CFString))
        assert(CGImageMetadataSetValueWithPath(data, nil, "GPano:CroppedAreaImageWidthPixels" as CFString, "\(image.width)" as CFString))
        assert(CGImageMetadataSetValueWithPath(data, nil, "GPano:CroppedAreaImageHeightPixels" as CFString, "\(image.height)" as CFString))
        assert(CGImageMetadataSetValueWithPath(data, nil, "GPano:StitchingSoftware" as CFString, "DSCVR 360" as CFString))
        assert(CGImageMetadataSetValueWithPath(data, nil, "GPano:CaptureSoftware" as CFString, "DSCVR 360" as CFString))
        
        print(data)
        
        CGImageDestinationAddImageAndMetadata(destination!, image, data, nil)
        CGImageDestinationFinalize(destination!)
        
        do {
            try PHPhotoLibrary.shared().performChangesAndWait {
                let creation = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(fileURLWithPath: filePath))
                let collection = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.smartAlbumPanoramas, options: nil)
                if let collection = collection.firstObject, let creation = creation {
                    PHAssetCollectionChangeRequest.init(for: collection)!.addAssets([creation.placeholderForCreatedAsset] as NSFastEnumeration)
                }
            }
        } catch {
            print("Error adding to gallery: \(error)")
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

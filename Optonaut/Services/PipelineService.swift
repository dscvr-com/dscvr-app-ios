//
//  PipelineService.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SQLite
import Async
import ReactiveCocoa
import Kingfisher
    
func ==(lhs: PipelineService.StitchingStatus, rhs: PipelineService.StitchingStatus) -> Bool {
    switch (lhs, rhs) {
    case (.Idle, .Idle): return true
    case (.Uninitialized, .Uninitialized): return true
    case let (.Stitching(lhs), .Stitching(rhs)): return lhs == rhs
    case let (.StitchingFinished(lhs), .StitchingFinished(rhs)): return lhs == rhs
    default: return false
    }
}

class PipelineService {
    
    enum StitchingStatus: Equatable {
        case Stitching(Float)
        case StitchingFinished(UUID)
        case Idle
        case Uninitialized
    }
    
    enum UploadingStatus: Equatable {
        case Uploading
//        case
    }
    
    typealias UploadSignal = Signal<UploadingStatus, NoError>
    
    static let stitchingStatus = MutableProperty<StitchingStatus>(.Uninitialized)
//    static var uploadingStatus: [UUID: UploadSignal] = [:]
    
    private static let uploadQueue = dispatch_queue_create("pipeline_upload", DISPATCH_QUEUE_SERIAL)
    
//    static func check() {
//        Async.main {
//            checkStitching()
//            checkUploading()
//        }
//    }
    
    static func stopStitching() {
        if StitchingService.isStitching() {
            StitchingService.cancelStitching()
        }
    }
    
    static func stitch(optographID: UUID) {
        let stitchingSignal = StitchingService.startStitching(optographID)
        
        let optographBox = Models.optographs[optographID]!
        
        stitchingSignal
            .observeOnUserInitiated()
            .observeNext { result in
                switch result {
                case let .Result(side, face, image):
                    
                    // This is a hack to circumvent asynchronous de/encoding of the image by Kingfisher. 
                    // We encode our image ourselves, and pass the encoded representation to Kingfisher. 
                    // Otherwise, the async method would retain the uncompressed image and use up a lot of memory. 
                    
                    let originalData = UIImageJPEGRepresentation(image, 0.9)!
                    let originalURL = TextureURL(optographID, side: side, size: 0, face: face, x: 0, y: 0, d: 1)
                    
                    sync(KingfisherManager.sharedManager) {
                        KingfisherManager.sharedManager.cache.storeImage(UIImage(data: originalData)!, originalData: originalData, forKey: originalURL, toDisk: true) {
                            upload(optographID, side: side, face: face)
                        }
                    }
                    
//                    let screen = UIScreen.mainScreen()
//                    let textureSize = getTextureWidth(screen.bounds.width, hfov: HorizontalFieldOfView)
                    // NOTE: this might be a bug in Kingfisher where UIImages automatically get scaled up
                    // https://github.com/onevcat/Kingfisher/issues/214
                    // let resizedData = UIImageJPEGRepresentation(image.resized(.Width, value: textureSize * screen.scale), 0.7)!
//                    let resizedData = UIImageJPEGRepresentation(image.resized(.Width, value: textureSize), 0.7)!
//                    let resizedURL = TextureURL(optographID, side: side, size: Int(textureSize), face: face, x: 0, y: 0, d: 1)
//                    KingfisherManager.sharedManager.cache.storeImage(UIImage(data: resizedData)!, originalData: resizedData, forKey: resizedURL)
                    
                case .Progress(let progress):
                    stitchingStatus.value = .Stitching(min(0.99, progress))
                }
            }
        
        stitchingSignal
            .on(completed: {
                StitchingService.removeUnstitchedRecordings()
            })
            .observeOnMain()
            .observeCompleted {
                optographBox.insertOrUpdate { box in
                    box.model.isStitched = true
                    box.model.stitcherVersion = StitcherVersion
                    box.model.isInFeed = true
                }
                stitchingStatus.value = .Stitching(1)
                stitchingStatus.value = .StitchingFinished(optographID)
            }
    }
    
    private static func upload(optographID: UUID) {
//        if let signal = uploadingStatus[optograph.ID] {
//            return signal
//        }

//        let (signal, observer) = UploadSignal.pipe()
        
        let optographBox = Models.optographs[optographID]!
        
        if let leftCubeTextureUploadStatus = optographBox.model.leftCubeTextureUploadStatus {
            for (index, uploaded) in leftCubeTextureUploadStatus.status.enumerate() {
                if !uploaded {
                    upload(optographID, side: .Left, face: index)
                }
            }
        }
        
        if let rightCubeTextureUploadStatus = optographBox.model.rightCubeTextureUploadStatus {
            for (index, uploaded) in rightCubeTextureUploadStatus.status.enumerate() {
                if !uploaded {
                    upload(optographID, side: .Right, face: index)
                }
            }
        }
        
//        return signal
    }
    
    private static func upload(optographID: UUID, side: TextureSide, face: Int) {
        Async.customQueue(uploadQueue) {
            let optographBox = Models.optographs[optographID]!
            
            switch side {
            case .Left where optographBox.model.leftCubeTextureUploadStatus?.status[face] == false: break
            case .Right where optographBox.model.rightCubeTextureUploadStatus?.status[face] == false: break
            default: return
            }
            
            let sideLetter = side == .Left ? "l" : "r"
            let url = TextureURL(optographID, side: .Left, size: 0, face: face, x: 0, y: 0, d: 1)
            
            objc_sync_enter(KingfisherManager.sharedManager)
            let image = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url)!
            objc_sync_exit(KingfisherManager.sharedManager)
            
            let result = ApiService<EmptyResponse>.upload("optographs/\(optographID)/upload-asset", multipartFormData: { form in
                form.appendBodyPart(data: "\(sideLetter)\(face)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "key")
                form.appendBodyPart(data: UIImageJPEGRepresentation(image, 1)!, name: "asset", fileName: "image.jpg", mimeType: "image/jpeg")
            })
                .transformToBool()
                .first()
            
            optographBox.insertOrUpdate { box in
                if result?.value == true {
                    switch side {
                    case .Left:
                        box.model.leftCubeTextureUploadStatus!.status[face] = true
                        if box.model.leftCubeTextureUploadStatus!.completed {
                            box.model.leftCubeTextureUploadStatus = nil
                        }
                    case .Right:
                        box.model.rightCubeTextureUploadStatus!.status[face] = true
                        if box.model.rightCubeTextureUploadStatus!.completed {
                            box.model.rightCubeTextureUploadStatus = nil
                        }
                    }
                    
                    if box.model.leftCubeTextureUploadStatus == nil && box.model.rightCubeTextureUploadStatus == nil {
                        box.model.isPublished = true
                    }
                } else {
                    box.model.shouldBePublished = false
                }
            }
        }
    }
    
    static func checkUploading() {
        let query = OptographTable
            .select(*)
            .filter(!OptographTable[OptographSchema.isPublished]
                && OptographTable[OptographSchema.isStitched]
                && OptographTable[OptographSchema.shouldBePublished]
                && OptographTable[OptographSchema.isSubmitted])
        
        let optographs = try! DatabaseService.defaultConnection.prepare(query).map(Optograph.fromSQL)
        
        if Reachability.connectedToNetwork() {
            for optograph in optographs {
                Models.optographs.touch(optograph)
                upload(optograph.ID)
            }
        }
    }
    
    static func checkStitching() {
        if StitchingService.isStitching() {
            return
        }
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .filter(!OptographTable[OptographSchema.isStitched] && OptographTable[OptographSchema.deletedAt] == nil)
        
        let optograph = DatabaseService.defaultConnection.pluck(query).map(Optograph.fromSQL)
        
        if let optographBox = Models.optographs.touch(optograph) {
            
            if !optographBox.model.isSubmitted {
                stitchingStatus.value = .Idle
                StitchingService.removeUnstitchedRecordings()
                optographBox.insertOrUpdate { box in
                    box.model.delete()
                }
            } else {
                stitch(optographBox.model.ID)
            }
            
        } else {
            stitchingStatus.value = .Idle
            
            if !StitchingService.isStitching() && StitchingService.hasUnstitchedRecordings() {
                // This happens when an optograph was recorded, but never
                // inserted into the DB, for example due to cancel.
                // So it needs to be removed.
                StitchingService.removeUnstitchedRecordings()
            }
        }
    }
    
}
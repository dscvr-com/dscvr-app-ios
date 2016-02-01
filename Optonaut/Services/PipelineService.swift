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
    
//    enum UploadingStatus: Equatable {
//        case Uploading
////        case
//    }
    
//    typealias UploadSignal = Signal<UploadingStatus, NoError>
//    static var uploadingStatus: [UUID: UploadSignal] = [:]
    
    static let stitchingStatus = MutableProperty<StitchingStatus>(.Uninitialized)
    
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
                    
                    ImageManager.sharedInstance.addImageToCache(NSURL(string: originalURL)!, originalData: originalData, image: UIImage(data: originalData)!) {
                            optographBox.insertOrUpdate { box in
                                switch side {
                                case .Left:
                                    // optional needed for when stitching was restarted textures already saved (stitcher could deliver results twice)
                                    box.model.leftCubeTextureStatusSave?.status[face] = true
                                    if box.model.leftCubeTextureStatusSave?.completed == true {
                                        box.model.leftCubeTextureStatusSave = nil
                                    }
                                case .Right:
                                    // optional needed for when stitching was restarted textures already saved (stitcher could deliver results twice)
                                    box.model.rightCubeTextureStatusSave?.status[face] = true
                                    if box.model.rightCubeTextureStatusSave?.completed == true {
                                        box.model.rightCubeTextureStatusSave = nil
                                    }
                                }
                                
                                if box.model.leftCubeTextureStatusSave == nil && box.model.rightCubeTextureStatusSave == nil {
                                    box.model.isStitched = true
                                    box.model.stitcherVersion = StitcherVersion
                                    box.model.isInFeed = true
                                }
                            }
                            
                            if optographBox.model.shouldBePublished {
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
                stitchingStatus.value = .Stitching(1)
                stitchingStatus.value = .StitchingFinished(optographID)
                upload(optographID)
            }
    }
    
    private static func upload(optographID: UUID) {
        
        let optographBox = Models.optographs[optographID]!
        
        if let leftCubeTextureUploadStatus = optographBox.model.leftCubeTextureStatusUpload {
            for (index, uploaded) in leftCubeTextureUploadStatus.status.enumerate() {
                if !uploaded {
                    upload(optographID, side: .Left, face: index)
                }
            }
        }
        
        if let rightCubeTextureUploadStatus = optographBox.model.rightCubeTextureStatusUpload {
            for (index, uploaded) in rightCubeTextureUploadStatus.status.enumerate() {
                if !uploaded {
                    upload(optographID, side: .Right, face: index)
                }
            }
        }
    }
    
    private static func upload(optographID: UUID, side: TextureSide, face: Int) {
        Async.customQueue(uploadQueue) {
            
            let optographBox = Models.optographs[optographID]!
            
            switch side {
            case .Left where optographBox.model.leftCubeTextureStatusUpload?.status[face] == false: break
            case .Right where optographBox.model.rightCubeTextureStatusUpload?.status[face] == false: break
            default: return
            }
            
            optographBox.update { box in
                box.model.isUploading = true
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
                        box.model.leftCubeTextureStatusUpload!.status[face] = true
                        if box.model.leftCubeTextureStatusUpload!.completed {
                            box.model.leftCubeTextureStatusUpload = nil
                        }
                    case .Right:
                        box.model.rightCubeTextureStatusUpload!.status[face] = true
                        if box.model.rightCubeTextureStatusUpload!.completed {
                            box.model.rightCubeTextureStatusUpload = nil
                        }
                    }
                    
                    if box.model.leftCubeTextureStatusUpload == nil && box.model.rightCubeTextureStatusUpload == nil {
                        box.model.isPublished = true
                        box.model.isUploading = false
                    }
                } else {
                    box.model.shouldBePublished = false
                    box.model.isUploading = false
                }
            }
        }
    }
    
    static func checkUploading() {
        let query = OptographTable
            .select(*)
            .filter(!OptographTable[OptographSchema.isPublished]
                && OptographTable[OptographSchema.isOnServer]
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
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
import ReactiveSwift
import Kingfisher
    
func ==(lhs: PipelineService.StitchingStatus, rhs: PipelineService.StitchingStatus) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle): return true
    case (.uninitialized, .uninitialized): return true
    case let (.stitching(lhs), .stitching(rhs)): return lhs == rhs
    case let (.stitchingFinished(lhs), .stitchingFinished(rhs)): return lhs == rhs
    default: return false
    }
}

class PipelineService {
    
    enum StitchingStatus: Equatable {
        case stitching(Float)
        case stitchingFinished(UUID)
        case idle
        case uninitialized
    }
    
//    enum UploadingStatus: Equatable {
//        case Uploading
////        case
//    }
    
//    typealias UploadSignal = Signal<UploadingStatus, NoError>
//    static var uploadingStatus: [UUID: UploadSignal] = [:]
    
    static let stitchingStatus = MutableProperty<StitchingStatus>(.uninitialized)
    
    fileprivate static let uploadQueue = DispatchQueue(label: "pipeline_upload", attributes: [])
    
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
    
    static func stitch(_ optographID: UUID) {
        stitchingStatus.value = .stitching(0.01)
        
        let stitchingSignal = StitchingService.startStitching(optographID)
        
        let optographBox = Models.optographs[optographID]!
        
        stitchingSignal
            .observeOnUserInitiated()
            .ignoreError() // TODO - no idea if this is safe. 
            .observeValues { result in
                switch result {
                case let .result(side, face, image):
                    
                    // This is a hack to circumvent asynchronous de/encoding of the image by Kingfisher. 
                    // We encode our image ourselves, and pass the encoded representation to Kingfisher.
                    // Otherwise, the async method would retain the uncompressed image and use up a lot of memory. 
                    
                    let originalData = UIImageJPEGRepresentation(image, 0.9)!
                    let originalURL = TextureURL(optographID, side: side, size: 0, face: face, x: 0, y: 0, d: 1)
                    
                    ImageManager.sharedInstance.addImageToCache(URL(string: originalURL)!, originalData: originalData, image: UIImage(data: originalData)!) {
                            optographBox.insertOrUpdate { box in
                                switch side {
                                case .left:
                                    // optional needed for when stitching was restarted textures already saved (stitcher could deliver results twice)
                                    box.model.leftCubeTextureStatusSave?.status[face] = true
                                    if box.model.leftCubeTextureStatusSave?.completed == true {
                                        box.model.leftCubeTextureStatusSave = nil
                                    }
                                case .right:
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
                    
                case .progress(let progress):
                    stitchingStatus.value = .stitching(min(0.99, progress))
                }
            }
        
        stitchingSignal
            .on(completed: {
                print("remove")
                StitchingService.removeUnstitchedRecordings()
            })
            .observeOnMain()
            .observeCompleted {
                stitchingStatus.value = .stitching(1)
                stitchingStatus.value = .stitchingFinished(optographID)
//                if optographBox.model.shouldBePublished {
//                    upload(optographID)
//                }
            }
    }
    
    fileprivate static func upload(_ optographID: UUID) {
        
        let optographBox = Models.optographs[optographID]!
        
        if let leftCubeTextureUploadStatus = optographBox.model.leftCubeTextureStatusUpload {
            for (index, uploaded) in leftCubeTextureUploadStatus.status.enumerated() {
                if !uploaded {
                    upload(optographID, side: .left, face: index)
                }
            }
        }
        
        if let rightCubeTextureUploadStatus = optographBox.model.rightCubeTextureStatusUpload {
            for (index, uploaded) in rightCubeTextureUploadStatus.status.enumerated() {
                if !uploaded {
                    upload(optographID, side: .right, face: index)
                }
            }
        }
    }
    
    fileprivate static func upload(_ optographID: UUID, side: TextureSide, face: Int) {
        Async.custom(queue: uploadQueue) {
            
            switch side {
                case .left: print("uploading left \(face)")
                case .right: print("uploading right \(face)")
            }
            
            let optographBox = Models.optographs[optographID]!
            
            switch side {
            case .left where optographBox.model.leftCubeTextureStatusUpload?.status[face] == false: break
            case .right where optographBox.model.rightCubeTextureStatusUpload?.status[face] == false: break
            default: return
            }
            
            optographBox.update { box in
                box.model.isUploading = true
            }
            
            let sideLetter = side == .left ? "l" : "r"
            let url = TextureURL(optographID, side: side, size: 0, face: face, x: 0, y: 0, d: 1)
            
            objc_sync_enter(KingfisherManager.shared)
            let image = KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: url)!
            objc_sync_exit(KingfisherManager.shared)
            
            optographBox.insertOrUpdate { box in
                switch side {
                    case .left:
                        box.model.leftCubeTextureStatusUpload!.status[face] = true
                        if box.model.leftCubeTextureStatusUpload!.completed {
                            box.model.leftCubeTextureStatusUpload = nil
                        }
                    case .right:
                        box.model.rightCubeTextureStatusUpload!.status[face] = true
                        if box.model.rightCubeTextureStatusUpload!.completed {
                            box.model.rightCubeTextureStatusUpload = nil
                        }
                }
                
                if box.model.leftCubeTextureStatusUpload == nil && box.model.rightCubeTextureStatusUpload == nil {
                    box.model.isPublished = true
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
                print("optoid",optograph.ID)
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
            .filter(!OptographTable[OptographSchema.isStitched] && OptographTable[OptographSchema.deletedAt] == nil)
        
        let optograph = try! DatabaseService.defaultConnection.pluck(query).map(Optograph.fromSQL)
        
        if let optographBox = Models.optographs.touch(optograph) {
            
            if !optographBox.model.isSubmitted {
                stitchingStatus.value = .idle
                print("remove check")
                StitchingService.removeUnstitchedRecordings()
                optographBox.insertOrUpdate { box in
                    box.model.delete()
                }
            } else {
                stitch(optographBox.model.ID)
            }
            
        } else {
            stitchingStatus.value = .idle
            
            if !StitchingService.isStitching() && StitchingService.hasUnstitchedRecordings() {
                // This happens when an optograph was recorded, but never
                // inserted into the DB, for example due to cancel.
                // So it needs to be removed.
                
                StitchingService.removeUnstitchedRecordings()
            }
        }
    }
    
}

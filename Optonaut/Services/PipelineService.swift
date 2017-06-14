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
        
        stitchingSignal
            .observeOnUserInitiated()
            .ignoreError() // TODO - no idea if this is safe. 
            .observeValues { result in
                switch result {
                case let .result(side, face, image):
                    ImageStore.saveFace(image: image, optographId: optographID, side: side == .left ? "left" : "right", face: face)
                case .progress(let progress):
                    stitchingStatus.value = .stitching(min(0.99, progress))
                }
            }
        
        stitchingSignal
            .on(completed: {
                print("remove")
                
                var optograph = DataBase.sharedInstance.getOptograph(id: optographID)
                optograph.isStitched = true
                print("Saving: \(optographID)")
                optograph.stitcherVersion = StitcherVersion
                DataBase.sharedInstance.saveOptograph(optograph: optograph)
                
                StitchingService.removeUnstitchedRecordings()
                let optographIDDict:[String: String] = ["id": optographID]
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: stitchingFinishedNotificationKey), object: self, userInfo: optographIDDict)
            })
            .observeOnMain()
            .observeCompleted {
                stitchingStatus.value = .stitching(1)
                stitchingStatus.value = .stitchingFinished(optographID)
                
            }
    }
    
    static func checkStitching() {
        if StitchingService.isStitching() {
            return
        }
        
        
        // TODO: Load optograph from optographId
        // TODO: We need the only optograph that's not stitched yet. 
        let optographs = DataBase.sharedInstance.getUnstitchedOptographs()
        
        if optographs.count > 0 {
            stitch(optographs[0].ID)
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

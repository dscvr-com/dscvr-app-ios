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
        case StitchingFinished(Optograph)
        case Idle
        case Uninitialized
    }
    
    enum UploadingStatus: Equatable {
        case Uploading
//        case
    }
    
    typealias UploadSignal = Signal<UploadingStatus, NoError>
    
    static let stitchingStatus = MutableProperty<StitchingStatus>(.Uninitialized)
    static var uploadingStatus: [UUID: UploadSignal] = [:]
    
    private static let uploadQueue = dispatch_queue_create("pipeline_upload", DISPATCH_QUEUE_CONCURRENT)
    
    static func check() {
        Async.main {
            updateOptographs()
        }
    }
    
    static func stop() {
        if StitchingService.isStitching() {
            StitchingService.cancelStitching()
        }
    }
    
    static func stitch(var optograph: Optograph) {
        let stitchingSignal = StitchingService.startStitching(optograph)
        
        stitchingSignal
            .observeNext { result in
                switch result {
                case let .Result(side, face, image):
                    
                    // This is a hack to circumvent asynchronous de/encoding of the image by Kingfisher. 
                    // We encode our image ourselves, and pass the encoded representation to Kingfisher. 
                    // Otherwise, the async method would retain the uncompressed image and use up a lot of memory. 
                    
                    let originalData = UIImageJPEGRepresentation(image, 0.9)!
                    let originalURL = TextureURL(optograph.ID, side: side, size: 0, face: face, x: 0, y: 0, d: 1)
                    KingfisherManager.sharedManager.cache.storeImage(UIImage(data: originalData)!, originalData: originalData, forKey: originalURL)
                    
                    let screen = UIScreen.mainScreen()
                    let textureSize = getTextureWidth(screen.bounds.width, hfov: HorizontalFieldOfView)
                    // NOTE: this might be a bug in Kingfisher where UIImages automatically get scaled up
                    // https://github.com/onevcat/Kingfisher/issues/214
                    // let resizedData = UIImageJPEGRepresentation(image.resized(.Width, value: textureSize * screen.scale), 0.7)!
                    let resizedData = UIImageJPEGRepresentation(image.resized(.Width, value: textureSize), 0.7)!
                    let resizedURL = TextureURL(optograph.ID, side: side, size: Int(textureSize), face: face, x: 0, y: 0, d: 1)
                    KingfisherManager.sharedManager.cache.storeImage(UIImage(data: resizedData)!, originalData: resizedData, forKey: resizedURL)
                    
                case .Progress(let progress):
                    stitchingStatus.value = .Stitching(min(0.99, progress))
                }
            }
        
        stitchingSignal
            .observeCompleted {
                optograph.isStitched = true
                optograph.stitcherVersion = StitcherVersion
                optograph.isInFeed = true
                try! optograph.insertOrUpdate()
                StitchingService.removeUnstitchedRecordings()
                stitchingStatus.value = .Stitching(1)
                stitchingStatus.value = .StitchingFinished(optograph)
                
                upload(optograph)
            }
    }
    
    static func upload(optograph: Optograph) -> UploadSignal {
        if let signal = uploadingStatus[optograph.ID] {
            return signal
        }

        let (signal, observer) = UploadSignal.pipe()
        
        Async.customQueue(uploadQueue) {
            if var leftCubeTextureUploadStatus = optograph.leftCubeTextureUploadStatus {
                for (index, uploaded) in leftCubeTextureUploadStatus.status.enumerate() {
                    if !uploaded {
                        let url = TextureURL(optograph.ID, side: .Left, size: 0, face: index, x: 0, y: 0, d: 1)
                        let image = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url)!
                        
                        print("upload l\(index)")
                        
                        let result = ApiService<EmptyResponse>.upload("optographs/\(optograph.ID)/upload-asset", multipartFormData: { form in
                            form.appendBodyPart(data: "l\(index)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "key")
                            form.appendBodyPart(data: UIImageJPEGRepresentation(image, 1)!, name: "asset", fileName: "image.jpg", mimeType: "image/jpeg")
                        })
                            .transformToBool()
                            .first()
                        
                        leftCubeTextureUploadStatus.status[index] = result?.value == true
                    }
                }
                
                print(leftCubeTextureUploadStatus.status)
            }
            
            if var rightCubeTextureUploadStatus = optograph.rightCubeTextureUploadStatus {
                for (index, uploaded) in rightCubeTextureUploadStatus.status.enumerate() {
                    if !uploaded {
                        let url = TextureURL(optograph.ID, side: .Right, size: 0, face: index, x: 0, y: 0, d: 1)
                        let image = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url)!
                        
                        print("upload r\(index)")
                        
                        let result = ApiService<EmptyResponse>.upload("optographs/\(optograph.ID)/upload-asset", multipartFormData: { form in
                            form.appendBodyPart(data: "r\(index)".dataUsingEncoding(NSUTF8StringEncoding)!, name: "key")
                            form.appendBodyPart(data: UIImageJPEGRepresentation(image, 1)!, name: "asset", fileName: "image.jpg", mimeType: "image/jpeg")
                        })
                            .transformToBool()
                            .first()
                        
                        rightCubeTextureUploadStatus.status[index] = result?.value == true
                    }
                }
                
                print(rightCubeTextureUploadStatus.status)
            }
        }
        
        return signal
    }
    
    private static func updateOptographs() {
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .filter(!OptographTable[OptographSchema.isStitched] && OptographTable[OptographSchema.deletedAt] == nil)
        
        let optograph = DatabaseService.defaultConnection.pluck(query)
            .map { row -> Optograph in
                var optograph = Optograph.fromSQL(row)
                
                optograph.person = Person.fromSQL(row)
                optograph.location = row[OptographSchema.locationID] == nil ? nil : Location.fromSQL(row)
                
                return optograph
            }
        
        if var optograph = optograph {
            
            if !optograph.isSubmitted {
                stitchingStatus.value = .Idle
                StitchingService.removeUnstitchedRecordings()
                optograph.delete().start()
            } else {
                stitch(optograph)
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
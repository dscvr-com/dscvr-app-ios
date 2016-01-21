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
    
func ==(lhs: PipelineService.Status, rhs: PipelineService.Status) -> Bool {
    switch (lhs, rhs) {
    case let (.Stitching(lhs), .Stitching(rhs)): return lhs == rhs
    case let (.StitchingFinished(lhs), .StitchingFinished(rhs)): return lhs == rhs
    default: return false
    }
}

class PipelineService {
    
    enum Status: Equatable {
        case Stitching(Float)
        case StitchingFinished(Optograph)
        case Idle
        case Disabled
    }
    
    static let status = MutableProperty<Status>(.Disabled)
    
    static func check() {
        Async.main {
            updateOptographs()
        }
    }
    
    static func stop(ID: UUID) {
        if StitchingService.isStitching() {
            StitchingService.cancelStitching()
        }
    }
    
    private static func updateOptographs() {
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .filter(!OptographTable[OptographSchema.isStitched])
        
        let optograph = DatabaseService.defaultConnection.pluck(query)
            .map { row -> Optograph in
                var optograph = Optograph.fromSQL(row)
                
                optograph.person = Person.fromSQL(row)
                optograph.location = row[OptographSchema.locationID] == nil ? nil : Location.fromSQL(row)
                
                return optograph
            }
        
        if var optograph = optograph {
            let stitchingSignal = StitchingService.startStitching(optograph)
            
            stitchingSignal
                .observeNext { result in
                    switch result {
                    case let .Result(side, face, image):
                        
                        // This is a hack to circumvent asynchronous de/encoding of the image by Kingfisher. 
                        // We encode our image ourselves, and pass the encoded representation to Kingfisher. 
                        // Otherwise, the async method would retain the uncompressed image and use up a lot of memory. 
                        
                        // let originalData = UIImageJPEGRepresentation(image, 0.9)!
                        // let originalURL = TextureURL(optograph.ID, side: side, size: 0, face: face, x: 0, y: 0, d: 1)
                        // KingfisherManager.sharedManager.cache.storeImage(UIImage(data: originalData)!, originalData: originalData, forKey: originalURL)
                        
                        let resizedData = UIImageJPEGRepresentation(image.resized(.Width, value: 1024 * UIScreen.mainScreen().scale), 0.8)!
                        let resizedURL = TextureURL(optograph.ID, side: side, size: 1024, face: face, x: 0, y: 0, d: 1)
                        KingfisherManager.sharedManager.cache.storeImage(UIImage(data: resizedData)!, originalData: resizedData, forKey: resizedURL)                    case .Progress(let progress):
                        status.value = .Stitching(min(0.99, progress))
                    }
                }
            
            stitchingSignal
                .observeCompleted {
                    optograph.isStitched = true
                    optograph.stitcherVersion = StitcherVersion
                    optograph.isInFeed = true
                    try! optograph.insertOrUpdate()
                    StitchingService.removeUnstitchedRecordings()
                    status.value = .Stitching(1)
                    status.value = .StitchingFinished(optograph)
                }
            
        } else {
            status.value = .Idle
            
            if !StitchingService.isStitching() && StitchingService.hasUnstitchedRecordings() {
                // This happens when an optograph was recorded, but never
                // inserted into the DB, for example due to cancel.
                // So it needs to be removed.
                StitchingService.removeUnstitchedRecordings()
            }
        }
    }
    
}
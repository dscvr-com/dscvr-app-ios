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

class PipelineService {
    
    private static let queue = dispatch_queue_create("PipelineQueue", DISPATCH_QUEUE_SERIAL)
    
    static func check() {
        Async.customQueue(queue) {
            sequentialStitch(toStitch())
            sequentialUpload(toUpload())
        }
    }
    
    private static func toStitch() -> [Optograph] {
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(!OptographTable[OptographSchema.isStitched])
        
        return DatabaseService.defaultConnection.prepare(query)
            .map { row -> Optograph in
                let person = Person.fromSQL(row)
                let location = Location.fromSQL(row)
                var optograph = Optograph.fromSQL(row)
                
                optograph.person = person
                optograph.location = location
                
                return optograph
            }
    }
    
    private static func toUpload() -> [Optograph] {
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(OptographTable[OptographSchema.isStitched] && !OptographTable[OptographSchema.isPublished])
        
        return DatabaseService.defaultConnection.prepare(query)
            .map { row -> Optograph in
                let person = Person.fromSQL(row)
                let location = Location.fromSQL(row)
                var optograph = Optograph.fromSQL(row)
                
                optograph.person = person
                optograph.location = location
                
                return optograph
            }
    }
    
    private static func sequentialStitch(var optographs: [Optograph]) {
        guard var optograph = optographs.popLast() else {
            if StitchingService.hasUnstitchedRecordings() {
                // This happens when an optograph was recorded, but never
                // inserted into the DB, for example due to cancel. 
                // Remove it. 
                StitchingService.removeUnstitchedRecordings()
            }
            return
        }
        
        if optograph.isStitched {
            //TODO: Make this method iterative.
            return sequentialStitch(optographs)
        }
        
        let signal = StitchingService.startStitching()
        
        signal.observeNext { result in
            switch result {
            case .LeftImage(let data): optograph.saveAsset(.LeftImage(data))
            case .RightImage(let data): optograph.saveAsset(.RightImage(data))
            default: break
            }
        }
        
        signal
            .observeOn(UIScheduler())
            .observeCompleted {
                optograph.isStitched = true
                try! optograph.insertOrUpdate()
                StitchingService.removeUnstitchedRecordings()
                PipelineService.check()
            }
    }
    
    private static func sequentialUpload(var optographs: [Optograph]) {
        guard var optograph = optographs.popLast() else {
            return
        }
        
        if optograph.isPublished {
            return sequentialUpload(optographs)
        }
        
        optograph.publish().startWithCompleted {
            sequentialUpload(optographs)
        }
    }
    
}
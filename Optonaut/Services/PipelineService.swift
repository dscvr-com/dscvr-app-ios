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
    
func ==(lhs: PipelineService.Status, rhs: PipelineService.Status) -> Bool {
    switch (lhs, rhs) {
    case let (.Stitching(lhs), .Stitching(rhs)): return lhs == rhs
    case let (.Publishing(lhs), .Publishing(rhs)): return lhs == rhs
    case (.StitchingFinished, .StitchingFinished): return true
    case (.PublishingFinished, .PublishingFinished): return true
    default: return false
    }
}

class PipelineService {
    
    enum Status: Equatable {
        case Stitching(Float)
        case StitchingFinished
        case Publishing(Float)
        case PublishingFinished
    }
    
    typealias StatusSignal = Signal<Status, NoError>
    private typealias StatusSignalPair = (signal: StatusSignal, disposable: Disposable)
    
    private static var signals: [UUID: StatusSignalPair] = [:]
    
    static func check() {
        Async.main {
            updateOptographs()
        }
    }
    
    static func statusSignalForOptograph(ID: UUID) -> StatusSignal? {
        return signals[ID]?.signal
    }
    
    static func stop(ID: UUID) {
        signals[ID]?.disposable.dispose()
        signals[ID] = nil
    }
    
    private static func updateOptographs() {
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .filter(!OptographTable[OptographSchema.isStitched] || !OptographTable[OptographSchema.isPublished])
        
        let optographs = DatabaseService.defaultConnection.prepare(query)
            .map { row -> Optograph in
                var optograph = Optograph.fromSQL(row)
                
                optograph.person = Person.fromSQL(row)
                optograph.location = row[OptographSchema.locationID] == nil ? nil : Location.fromSQL(row)
                
                return optograph
            }
            .filter { signals[$0.ID] == nil }
            
        optographs.forEach { optograph in
            if !optograph.isStitched {
                signals[optograph.ID] = stitch(optograph)
            } else if Reachability.connectedToNetwork() && SessionService.isLoggedIn {
                signals[optograph.ID] = publish(optograph)
            }
        }
        
        if optographs.filter({ !$0.isStitched }).isEmpty && !StitchingService.isStitching() && StitchingService.hasUnstitchedRecordings() {
            // This happens when an optograph was recorded, but never
            // inserted into the DB, for example due to cancel.
            // So it needs to be removed.
            StitchingService.removeUnstitchedRecordings()
        }
    }
    
    private static func publish(var optograph: Optograph) -> StatusSignalPair {
        let (signal, sink) = StatusSignal.pipe()
        
        let disposable = optograph.publish()
            .on(
                started: {
                    sink.sendNext(.Publishing(0))
                },
                completed: {
                    sink.sendNext(.Publishing(1))
                    signals.removeValueForKey(optograph.ID)
                    sink.sendNext(.PublishingFinished)
                    sink.sendCompleted()
                },
                error: { _ in
                    NotificationService.push("Publishing failed...", level: .Warning)
                    signals.removeValueForKey(optograph.ID)
                    PipelineService.check()
                }
            )
            .start()
    
        return (signal, disposable)
    }
    
    private static func stitch(var optograph: Optograph) -> StatusSignalPair {
        
        let (signal, sink) = StatusSignal.pipe()
        let stitchingSignal = StitchingService.startStitching(optograph)
        
        stitchingSignal
            .observeNext { result in
                switch result {
                case .LeftImage(let data): optograph.saveAsset(.LeftImage(data))
                case .RightImage(let data): optograph.saveAsset(.RightImage(data))
                case .Progress(let progress): sink.sendNext(.Stitching(min(0.99, progress)))
                }
            }
        
        stitchingSignal
            .observeCompleted {
                optograph.isStitched = true
                optograph.stitcherVersion = StitcherVersion
                try! optograph.insertOrUpdate()
                StitchingService.removeUnstitchedRecordings()
                signals.removeValueForKey(optograph.ID)
                sink.sendNext(.Stitching(1))
                sink.sendNext(.StitchingFinished)
                sink.sendCompleted()
                PipelineService.check()
            }
        
        let disposable = ActionDisposable {
            StitchingService.cancelStitching()
        }
        
        return (signal, disposable)
    }
    
}
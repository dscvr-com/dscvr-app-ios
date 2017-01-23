//
//  FeedViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/23/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite
import SwiftyUserDefaults

class FeedOptographCollectionViewModel: OptographCollectionViewModel {
    
    private var refreshTimer: NSTimer?
    
    let results = MutableProperty<TableViewResults<Optograph>>(.empty())
    let isActive = MutableProperty<Bool>(false)
    
    private let refreshNotification = NotificationSignal<Void>()
    
    init() {
        
        let query = OptographTable.select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .filter(OptographTable[OptographSchema.isInFeed] && OptographTable[OptographSchema.deletedAt] == nil)
            .order(OptographTable[OptographSchema.createdAt].asc)
        
        refreshNotification.signal
            .flatMap(.Latest) { _ in
                DatabaseService.query(.Many, query: query)
                    .observeOnUserInteractive()
                    .on(next: { row in
                        Models.optographs.touch(Optograph.fromSQL(row))
                        Models.persons.touch(Person.fromSQL(row))
                        Models.locations.touch(row[OptographSchema.locationID] != nil ? Location.fromSQL(row) : nil)
                    })
                    .map(Optograph.fromSQL)
                    .ignoreError()
                    .collect()
                    .startOnUserInteractive()
            }   
            .observeOnMain()
            .map {self.results.value.merge($0, deleteOld: false) }
            .observeNext { self.results.value = $0 }
 
        
        isActive.producer.skipRepeats().startWithNext { [weak self] isActive in
            if isActive {
                self?.refresh()
            } else {
                self?.refreshTimer?.invalidate()
            }
        }
        
        PipelineService.stitchingStatus.producer
            .startWithNext { [weak self] status in
                if case .StitchingFinished(_) = status {
                    self?.refresh()
                }
        }
    }
    
    func refresh() {
        refreshNotification.notify(())
    }
    
}
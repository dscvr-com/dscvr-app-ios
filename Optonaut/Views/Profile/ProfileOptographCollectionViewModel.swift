//
//  OptographsTableViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/25/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class ProfileOptographCollectionViewModel: OptographCollectionViewModel {
    
    private var refreshTimer: NSTimer?
    
    let results = MutableProperty<TableViewResults<Optograph>>(.empty())
    let isActive = MutableProperty<Bool>(false)
    
    private let refreshNotification = NotificationSignal<Void>()
    private let loadMoreNotification = NotificationSignal<Void>()
    
    init(personID: UUID, selectedOptographID: UUID) {
        
        let selectedOptograph = Models.optographs[selectedOptographID]!.model
        results.value = results.value.merge([selectedOptograph], deleteOld: false)
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .filter(PersonTable[PersonSchema.ID] == personID)
        
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
            .map { self.results.value.merge($0, deleteOld: false) }
            .observeNext { self.results.value = $0 }
        
        
        refreshNotification.signal
            .takeWhile { _ in Reachability.connectedToNetwork() }
            .flatMap(.Latest) { _ in
                ApiService<OptographApiModel>.get("persons/\(personID)/optographs")
                    .observeOnUserInitiated()
                    .on(next: { apiModel in
                        Models.optographs.touch(apiModel).insertOrUpdate { box in
                            box.model.isStitched = true
                            box.model.isPublished = true
                            box.model.isSubmitted = true
                        }
                        Models.persons.touch(apiModel.person).insertOrUpdate()
                        Models.locations.touch(apiModel.location)?.insertOrUpdate()
                    })
                    .map(Optograph.fromApiModel)
                    .ignoreError()
                    .collect()
                    .startOnUserInitiated()
            }
            .observeOnMain()
            .map { self.results.value.merge($0, deleteOld: false) }
            .observeNext { self.results.value = $0 }
        
        loadMoreNotification.signal
            .map { _ in self.results.value.models.last }
            .ignoreNil()
            .flatMap(.Latest) { oldestResult in
                ApiService<OptographApiModel>.get("persons/\(personID)/optographs", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
                    .observeOnUserInitiated()
                    .on(next: { apiModel in
                        Models.optographs.touch(apiModel).insertOrUpdate { box in
                            box.model.isStitched = true
                            box.model.isPublished = true
                            box.model.isSubmitted = true
                        }
                        Models.persons.touch(apiModel.person).insertOrUpdate()
                        Models.locations.touch(apiModel.location)?.insertOrUpdate()
                    })
                    .map(Optograph.fromApiModel)
                    .ignoreError()
                    .collect()
                    .startOnUserInitiated()
            }
            .observeOnMain()
            .map { self.results.value.merge($0, deleteOld: false) }
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
    
    deinit {
        refreshTimer?.invalidate()
        refreshNotification.dispose()
        loadMoreNotification.dispose()
        
        logRetain()
    }
    
    dynamic func refresh() {
        refreshNotification.notify(())
        refreshTimer?.invalidate()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
    }
    
    func loadMore() {
        loadMoreNotification.notify(())
    }
    
    
}
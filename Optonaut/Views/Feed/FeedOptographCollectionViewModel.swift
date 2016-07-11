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
//    let newResultsAvailable = MutableProperty<Bool>(false)
    let isActive = MutableProperty<Bool>(false)
    
    private let refreshNotification = NotificationSignal<Void>()
    private let loadMoreNotification = NotificationSignal<Void>()
    
    init() {
        
        let query = OptographTable.select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .filter(OptographTable[OptographSchema.isInFeed])
            .filter(OptographTable[OptographSchema.shouldBePublished])
            .order(OptographTable[OptographSchema.createdAt].asc)
        
        refreshNotification.signal.observeOnMain().observeNext{
            print("nakareceive ng signal")
        }
        
        refreshNotification.signal
            .flatMap(.Latest) { _ in
                DatabaseService.query(.Many, query: query)
                    .observeOnUserInitiated()
                    .on(next: { row in
                        Models.optographs.touch(Optograph.fromSQL(row))
                        Models.persons.touch(Person.fromSQL(row))
                        Models.locations.touch(row[OptographSchema.locationID] != nil ? Location.fromSQL(row) : nil)
                    })
                    .map(Optograph.fromSQL)
                    .ignoreError()
                    .collect()
                    .startOnUserInitiated()
            }
            .observeOnMain()
            .map {self.results.value.merge($0, deleteOld: false) }
            .observeNext { self.results.value = $0 }
    
        refreshNotification.signal
            .takeWhile { _ in Reachability.connectedToNetwork() }
            .flatMap(.Latest) { _ in
                ApiService<OptographApiModel>.get("optographs/feed")
                    .observeOnUserInitiated()
                    .on(next: { apiModel in
                        Models.optographs.touch(apiModel).insertOrUpdate { box in
                            box.model.isInFeed = true
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
            .observeNext { results in
//                self.newResultsAvailable.value = self.results.value.models.first?.ID != results.models.first?.ID
                self.results.value = results
            }

        loadMoreNotification.signal
            .map { _ in self.results.value.models.last }
            .ignoreNil()
            .flatMap(.Latest) { oldestResult in
                ApiService<OptographApiModel>.get("optographs/feed", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
                    .observeOnUserInitiated()
                    .on(next: { apiModel in
                        Models.optographs.touch(apiModel).insertOrUpdate { box in
                            box.model.isInFeed = true
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
        
        SessionService.onLogout { [weak self] in
            self?.refreshTimer?.invalidate()
            self?.refreshNotification.dispose()
            self?.loadMoreNotification.dispose()
        }
    }
    
    func refresh() {
        print("refresh function called!")
        refreshNotification.notify(())
//        refreshTimer?.invalidate()
//        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: #selector(FeedOptographCollectionViewModel.refresh), userInfo: nil, repeats: true)
    }
    
    func loadMore() {
        loadMoreNotification.notify(())
    }
    
}
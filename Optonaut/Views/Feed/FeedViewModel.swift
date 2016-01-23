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

struct TableViewResults<T: DeletableModel> {
    let insert: [Int]
    let update: [Int]
    let delete: [Int]
    let models: [T]
    
    static func empty() -> TableViewResults<T> {
        return TableViewResults<T>(insert: [], update: [], delete: [], models: [])
    }
    
    func merge(newModels: [T], deleteOld: Bool) -> TableViewResults<T> {

        var models = self.models
        
        var delete: [Int] = []
        for deletedModel in newModels.filter({ $0.deletedAt != nil }) {
            if let index = models.indexOf({ $0.ID == deletedModel.ID }) {
                delete.append(index)
            }
        }
        if deleteOld {
            for (index, model) in models.enumerate() {
                if newModels.indexOf({ $0.ID == model.ID }) == nil {
                    delete.append(index)
                }
            }
        }
        for deleteIndex in delete.sort().reverse() {
            models.removeAtIndex(deleteIndex)
        }
        
        var update: [Int] = []
        var exclusiveNewModels: [T] = []
        for newModel in newModels.filter({ $0.deletedAt == nil }) {
            if let index = models.indexOf({ $0.ID == newModel.ID }) {
                if models[index] != newModel {
                    update.append(index)
                    models[index] = newModel
                }
            } else {
                exclusiveNewModels.append(newModel)
            }
        }
        
        var insert: [Int] = []
        for newModel in exclusiveNewModels.sort({ $0.createdAt > $1.createdAt }) {
            if let index = models.indexOf({ $0.createdAt < newModel.createdAt }) {
                insert.append(index)
                models.insert(newModel, atIndex: index)
            } else {
                insert.append(models.count)
                models.append(newModel)
            }
        }
        
        return TableViewResults(insert: insert, update: update, delete: delete, models: models)
    }
}

class FeedViewModel: NSObject {
    
    private var refreshTimer: NSTimer!
    
    let results = MutableProperty<TableViewResults<Optograph>>(.empty())
    let newResultsAvailable = MutableProperty<Bool>(false)
    let isActive = MutableProperty<Bool>(false)
    
    let refreshNotification = NotificationSignal<Void>()
    let loadMoreNotification = NotificationSignal<Void>()
    
    override init() {
        
        super.init()
        
        let query = OptographTable.select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .filter(OptographTable[OptographSchema.isInFeed] && OptographTable[OptographSchema.deletedAt] == nil)
            .order(CommentSchema.createdAt.asc)
        
        refreshNotification.signal
            .flatMap(.Latest) { _ in
                DatabaseService.query(.Many, query: query)
                    .observeOnUserInteractive()
                    .map { row -> Optograph in
                        let optograph = Optograph.fromSQL(row)
                        
                        Models.optographs.touch(optograph)
                        Models.persons.touch(Person.fromSQL(row))
                        if row[OptographSchema.locationID] != nil {
                            Models.locations.touch(Location.fromSQL(row))
                        }
                        
                        return optograph
                    }
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
                ApiService<OptographApiModel>.get("optographs/feed")
                    .observeOnUserInitiated()
                    .on(next: { apiModel in
                        var optograph = apiModel.toModel()
                        
                        optograph.isInFeed = true
                        optograph.isStitched = true
                        optograph.isPublished = true
                        optograph.isSubmitted = true
                        
                        Models.optographs.touch(optograph).insertOrUpdate()
                        Models.persons.touch(apiModel.person.toModel()).insertOrUpdate()
                        Models.locations.touch(apiModel.location?.toModel())?.insertOrUpdate()
                    })
                    .map { $0.toModel() }
                    .ignoreError()
                    .collect()
                    .startOnUserInitiated()
            }
            .observeOnMain()
            .map { self.results.value.merge($0, deleteOld: false) }
            .observeNext { results in
                self.newResultsAvailable.value = self.results.value.models.first?.ID != results.models.first?.ID
                self.results.value = results
            }

        loadMoreNotification.signal
            .map { _ in self.results.value.models.last }
            .ignoreNil()
            .flatMap(.Latest) { oldestResult in
                ApiService<OptographApiModel>.get("optographs/feed", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
                    .observeOnUserInitiated()
                    .on(next: { apiModel in
                        var optograph = apiModel.toModel()
                        
                        optograph.isInFeed = true
                        optograph.isStitched = true
                        optograph.isPublished = true
                        optograph.isSubmitted = true
                        
                        Models.optographs.touch(optograph).insertOrUpdate()
                        Models.persons.touch(apiModel.person.toModel()).insertOrUpdate()
                        Models.locations.touch(apiModel.location?.toModel())?.insertOrUpdate()
                    })
                    .map { $0.toModel() }
                    .ignoreError()
                    .collect()
                    .startOnUserInitiated()
            }
            .observeOnMain()
            .map { self.results.value.merge($0, deleteOld: false) }
            .observeNext { self.results.value = $0 }
        
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
        
        PipelineService.stitchingStatus.producer
            .startWithNext { [weak self] status in
                if case .StitchingFinished(_) = status {
                    self?.refreshNotification.notify(())
                }
            }
        
        SessionService.onLogout { [weak self] in
            self?.refreshTimer.invalidate()
            self?.refreshNotification.dispose()
            self?.loadMoreNotification.dispose()
        }
    }
    
    func refresh() {
        refreshNotification.notify(())
    }
    
}
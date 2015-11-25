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
    
    let refreshNotification = NotificationSignal<Void>()
    let loadMoreNotification = NotificationSignal<Void>()
    
    override init() {
        
        super.init()
        
        let query = OptographTable.select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .filter(OptographTable[OptographSchema.isStaffPick] || PersonTable[PersonSchema.isFollowed] || PersonTable[PersonSchema.ID] == (Defaults[.SessionPersonID] ?? Person.guestID) || PersonTable[PersonSchema.ID] == Person.guestID)
            .order(CommentSchema.createdAt.asc)
        
        refreshNotification.signal
            .flatMap(.Latest) { _ in
                DatabaseService.query(.Many, query: query)
                    .observeOnUserInteractive()
                    .map { row -> Optograph in
                        var optograph = Optograph.fromSQL(row)
                        
                        optograph.person = Person.fromSQL(row)
                        optograph.location = row[OptographSchema.locationID] == nil ? nil : Location.fromSQL(row)
                        
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
                ApiService<Optograph>.get("optographs/feed")
                    .observeOnUserInteractive()
                    .on(next: { optograph in
                        try! optograph.insertOrUpdate()
                        try! optograph.location?.insertOrUpdate()
                        try! optograph.person.insertOrUpdate()
                    })
                    .ignoreError()
                    .collect()
                    .startOnUserInteractive()
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
                ApiService<Optograph>.get("optographs/feed", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
                    .observeOnUserInteractive()
                    .on(next: { optograph in
                        try! optograph.insertOrUpdate()
                        try! optograph.location?.insertOrUpdate()
                        try! optograph.person.insertOrUpdate()
                    })
                    .ignoreError()
                    .collect()
                    .startOnUserInteractive()
            }
            .observeOnMain()
            .map { self.results.value.merge($0, deleteOld: false) }
            .observeNext { self.results.value = $0 }
        
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
        
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
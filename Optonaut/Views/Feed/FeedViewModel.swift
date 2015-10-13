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

struct TableViewResults {
    let insert: [Int]
    let update: [Int]
    let delete: [Int]
    let optographs: [Optograph]
    
    static let empty = TableViewResults(insert: [], update: [], delete: [], optographs: [])
}

func mergeResults(newOptographs: [Optograph], oldOptographs: [Optograph]) -> TableViewResults {
    var optographs = oldOptographs
    
    var delete: [Int] = []
    for deletedOptograph in newOptographs.filter({ $0.deletedAt != nil }) {
        if let index = optographs.indexOf({ $0.id == deletedOptograph.id }) {
            delete.append(index)
        }
    }
    for deleteIndex in delete.sort().reverse() {
        optographs.removeAtIndex(deleteIndex)
    }
    
    var update: [Int] = []
    var exclusiveNewOptographs: [Optograph] = []
    for newOptograph in newOptographs.filter({ $0.deletedAt == nil }) {
        if let index = optographs.indexOf({ $0.id == newOptograph.id }) {
            if optographs[index].starsCount != newOptograph.starsCount {
                update.append(index)
                optographs[index] = newOptograph
            }
        } else {
            exclusiveNewOptographs.append(newOptograph)
        }
    }
    
    var insert: [Int] = []
    for newOptograph in exclusiveNewOptographs.sort({ $0.createdAt > $1.createdAt }) {
        if let index = optographs.indexOf({ $0.createdAt < newOptograph.createdAt }) {
            insert.append(index)
            optographs.insert(newOptograph, atIndex: index)
        } else {
            insert.append(optographs.count)
            optographs.append(newOptograph)
        }
    }
    
    return TableViewResults(insert: insert, update: update, delete: delete, optographs: optographs)
}

class FeedViewModel: NSObject {
    
    var refreshTimer: NSTimer!
    
    let results = MutableProperty<TableViewResults>(.empty)
    let newResultsAvailable = MutableProperty<Bool>(false)
    
    let refreshNotification = NotificationSignal()
    let loadMoreNotification = NotificationSignal()
    
    override init() {
        super.init()
        
        let queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(PersonTable[PersonSchema.isFollowed] || PersonTable[PersonSchema.id] == SessionService.sessionData!.id)
//            .order(CommentSchema.createdAt.asc)
        
        refreshNotification.signal
            .mapError { _ in DatabaseQueryError.Nil }
            .flatMap(.Latest) { _ in
                DatabaseService.query(.Many, query: query)
                    .observeOn(QueueScheduler(queue: queue))
                    .map { row -> Optograph in
                        let person = Person.fromSQL(row)
                        let location = Location.fromSQL(row)
                        var optograph = Optograph.fromSQL(row)
                        
                        optograph.person = person
                        optograph.location = location
                        
                        return optograph
                    }
                    .collect()
                    .startOn(QueueScheduler(queue: queue))
            }
            .observeOn(UIScheduler())
            .map { mergeResults($0, oldOptographs: self.results.value.optographs) }
            .observeNext { self.results.value = $0 }
    
        refreshNotification.signal
            .mapError { _ in ApiError.Nil }
            .flatMap(.Latest) { _ in
                ApiService<Optograph>.get("optographs/feed")
                    .observeOn(QueueScheduler(queue: queue))
                    .on(next: { optograph in
                        try! optograph.insertOrUpdate()
                        try! optograph.location.insertOrUpdate()
                        try! optograph.person.insertOrUpdate()
                    })
                    .collect()
                    .startOn(QueueScheduler(queue: queue))
            }
            .observeOn(UIScheduler())
            .map { mergeResults($0, oldOptographs: self.results.value.optographs) }
            .observeNext { results in
                self.newResultsAvailable.value = self.results.value.optographs.first?.id != results.optographs.first?.id
                self.results.value = results
            }
        
//        loadMoreNotification.signal
//            .mapError { _ in ApiError.Nil }
//            .map { _ in self.results.value.last }
//            .ignoreNil()
//            .flatMap(.Latest) { oldestResult in
//                ApiService<Optograph>.get("optographs/feed", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
//                    .observeOn(QueueScheduler(queue: queue))
//                    .on(next: { optograph in
//                        try! optograph.insertOrUpdate()
//                        try! optograph.location.insertOrUpdate()
//                        try! optograph.person.insertOrUpdate()
//                    })
//                    .collect()
//                    .map { self.results.value.orderedMerge($0, withOrder: .OrderedDescending) }
//                    .startOn(QueueScheduler(queue: queue))
//            }
//            .observeOn(UIScheduler())
//            .observeNext { optographs in
//                self.results.value = optographs
//            }
        
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
        
        SessionService.onLogout { [weak self] in
            self?.refreshTimer.invalidate()
        }
    }
    
    func refresh() {
        refreshNotification.notify()
    }
    
}
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

class FeedViewModel: NSObject {
    
    var refreshTimer: NSTimer!
    
    let results = MutableProperty<[Optograph]>([])
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
                    .map { self.results.value.orderedMerge($0, withOrder: .OrderedDescending) }
                    .startOn(QueueScheduler(queue: queue))
            }
            .observeOn(UIScheduler())
            .observeNext { optographs in
//            .startWithNext { optographs in
                self.results.value = optographs
                // needed since Optograph could have been deleted in the meantime
                self.results.value = self.results.value.filter { !$0.deleted }
            }
        
        refreshNotification.signal
            .mapError { _ in ApiError.Nil }
            .flatMap(.Latest) { _ in
                ApiService<Optograph>.get("optographs/feed")
                    .observeOn(QueueScheduler(queue: queue))
                    .on(next: { optograph in
                        try! optograph.insertOrReplace()
                        try! optograph.location.insertOrReplace()
                        try! optograph.person.insertOrReplace()
                    })
                    .collect()
                    .map { self.results.value.orderedMerge($0, withOrder: .OrderedDescending) }
                    .startOn(QueueScheduler(queue: queue))
            }
            .observeOn(UIScheduler())
            .observeNext { optographs in
                self.newResultsAvailable.value = self.results.value.first?.id != optographs.first?.id
                self.results.value = optographs
            }
        
        loadMoreNotification.signal
            .mapError { _ in ApiError.Nil }
            .map { _ in self.results.value.last }
            .ignoreNil()
            .flatMap(.Latest) { oldestResult in
                ApiService<Optograph>.get("optographs/feed", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
                    .observeOn(QueueScheduler(queue: queue))
                    .on(next: { optograph in
                        try! optograph.insertOrReplace()
                        try! optograph.location.insertOrReplace()
                        try! optograph.person.insertOrReplace()
                    })
                    .collect()
                    .map { self.results.value.orderedMerge($0, withOrder: .OrderedDescending) }
                    .startOn(QueueScheduler(queue: queue))
            }
            .observeOn(UIScheduler())
            .observeNext { optographs in
                self.results.value = optographs
            }
        
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
        
        SessionService.onLogout { [weak self] in
            self?.refreshTimer.invalidate()
        }
    }
    
    func refresh() {
        refreshNotification.notify()
    }
    
}
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
    
    let refreshNotificationSignal = NotificationSignal()
    let loadMoreNotificationSignal = NotificationSignal()
    
    override init() {
        super.init()
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(PersonTable[PersonSchema.isFollowed] || PersonTable[PersonSchema.id] == SessionService.sessionData!.id)
//            .order(CommentSchema.createdAt.asc)
        
        refreshNotificationSignal.subscribe {
            DatabaseService.defaultConnection.prepare(query)
                .map({ row -> Optograph in
                    let person = Person.fromSQL(row)
                    let location = Location.fromSQL(row)
                    var optograph = Optograph.fromSQL(row)
                    
                    optograph.person = person
                    optograph.location = location
                    
                    return optograph
                })
                .forEach(self.processNewOptograph)
            
            var count = 0
            ApiService<Optograph>.get("optographs/feed")
                .startWithNext { optograph in
                    if let firstOptograph = self.results.value.first where count++ == 0 {
                        self.newResultsAvailable.value = optograph.id != firstOptograph.id
                    }
                    
                    self.processNewOptograph(optograph)
                    
                    try! optograph.insertOrReplace()
                    try! optograph.location.insertOrReplace()
                    try! optograph.person.insertOrReplace()
                }
        }
        
        loadMoreNotificationSignal.subscribe {
            if let oldestResult = self.results.value.last {
                ApiService<Optograph>.get("optographs/feed", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
                    .startWithNext { optograph in
                        self.processNewOptograph(optograph)
                        
                        try! optograph.insertOrReplace()
                        try! optograph.location.insertOrReplace()
                        try! optograph.person.insertOrReplace()
                    }
            }
        }
        
        refreshNotificationSignal.notify()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
        SessionService.onLogout(fn: self.refreshTimer.invalidate)
    }
    
    func refresh() {
        refreshNotificationSignal.notify()
    }
    
    private func processNewOptograph(optograph: Optograph) {
        results.value.orderedInsert(optograph, withOrder: .OrderedDescending)
        results.value.filterDeleted()
    }
    
}
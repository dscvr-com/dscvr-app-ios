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
        
//        let meId = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.PersonId.rawValue) as! UUID
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
//            .filter(PersonTable[PersonSchema.isFollowed] || PersonTable[PersonSchema.id] == meId)
//            .order(CommentSchema.createdAt.asc)
        
        let optographs = DatabaseManager.defaultConnection.prepare(query).map { row -> Optograph in
            let person = Person.fromSQL(row)
            let location = Location.fromSQL(row)
            var optograph = Optograph.fromSQL(row)
            
            optograph.person = person
            optograph.location = location
            
            return optograph
        }
        
        results.value = optographs.sort { $0.createdAt > $1.createdAt }
        
        refreshNotificationSignal.subscribe {
            ApiService.get("optographs/feed")
                .on(next: { (optograph: Optograph) in
                    if let firstOptograph = self.results.value.first {
                        self.newResultsAvailable.value = optograph.id != firstOptograph.id
                    }
                })
                .start(next: processNewOptograph)
        }
        
        loadMoreNotificationSignal.subscribe {
            ApiService.get("optographs/feed?offset=\(results.value.count)")
                .start(next: processNewOptograph)
        }
        
        refreshNotificationSignal.notify()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
    }
    
    func refresh() {
        refreshNotificationSignal.notify()
    }
    
    private func processNewOptograph(optograph: Optograph) {
        results.value.orderedInsert(optograph, withOrder: .OrderedDescending)
        
        try! DatabaseManager.defaultConnection.run(PersonTable.insert(or: .Replace, optograph.person.toSQL()))
        try! DatabaseManager.defaultConnection.run(LocationTable.insert(or: .Replace, optograph.location.toSQL()))
        try! DatabaseManager.defaultConnection.run(OptographTable.insert(or: .Replace, optograph.toSQL()))
    }
    
}
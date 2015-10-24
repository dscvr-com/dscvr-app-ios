//
//  ActivityViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/26/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class ActivitiesViewModel: NSObject {
    
    var refreshTimer: NSTimer!
    
    let results = MutableProperty<TableViewResults<Activity>>(.empty())
    let unreadCount = MutableProperty<Int>(0)
    
    let refreshNotification = NotificationSignal<Void>()
    let loadMoreNotification = NotificationSignal<Void>()
    
    override init() {
        super.init()
        
//        let query = ActivityTable.select(*)
//            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
//            .join(LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
//            .filter(PersonTable[PersonSchema.isFollowed] || PersonTable[PersonSchema.ID] == SessionService.sessionData!.ID)
//            .order(CommentSchema.createdAt.asc)
//        
//        refreshNotification.signal
//            .flatMap(.Latest) { _ in
//                DatabaseService.query(.Many, query: query)
//                    .observeOn(QueueScheduler(queue: queue))
//                    .map { row -> Optograph in
//                        let person = Person.fromSQL(row)
//                        let location = Location.fromSQL(row)
//                        var optograph = Optograph.fromSQL(row)
//                        
//                        optograph.person = person
//                        optograph.location = location
//                        
//                        return optograph
//                    }
//                    .ignoreError()
//                    .collect()
//                    .startOn(QueueScheduler(queue: queue))
//            }
//            .observeOn(UIScheduler())
//            .map { self.results.value.merge($0, deleteOld: false) }
//            .observeNext { self.results.value = $0 }
        
        refreshNotification.signal
            .takeWhile { _ in Reachability.connectedToNetwork() }
            .flatMap(.Latest) { _ in
                ApiService<Activity>.get("activities")
                    .observeOnUserInteractive()
                    .on(next: { activity in
                        try! activity.insertOrUpdate()
                        try! activity.activityResourceStar?.insertOrUpdate()
                        try! activity.activityResourceStar?.optograph.insertOrUpdate()
                        try! activity.activityResourceStar?.causingPerson.insertOrUpdate()
                        try! activity.activityResourceComment?.insertOrUpdate()
                        try! activity.activityResourceComment?.optograph.insertOrUpdate()
                        try! activity.activityResourceComment?.comment.insertOrUpdate()
                        try! activity.activityResourceComment?.causingPerson.insertOrUpdate()
                        try! activity.activityResourceViews?.insertOrUpdate()
                        try! activity.activityResourceViews?.optograph.insertOrUpdate()
                        try! activity.activityResourceFollow?.insertOrUpdate()
                        try! activity.activityResourceFollow?.causingPerson.insertOrUpdate()
                    })
                    .ignoreError()
                    .collect()
                    .startOnUserInteractive()
            }
            .observeOnMain()
            .map { self.results.value.merge($0, deleteOld: false) }
            .observeNext { results in
                self.unreadCount.value = results.models.reduce(0) { (acc, activity) in acc + (activity.isRead ? 0 : 1) }
                self.results.value = results
            }
        
        refreshNotification.notify(())
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

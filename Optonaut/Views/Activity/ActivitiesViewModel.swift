//
//  ActivityViewModel.swift
//  Optonaut
//
//  Created by Robert John Alkuino on 6/26/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class ActivitiesViewModel: NSObject {
    
    private var refreshTimer: NSTimer!
    
    let results = MutableProperty<TableViewResults<Activity>>(.empty())
    let unreadCount: MutableProperty<Int>
    
    let refreshNotification = NotificationSignal<Void>()
    let loadMoreNotification = NotificationSignal<Void>()
    
    override init() {
        unreadCount = MutableProperty(UIApplication.sharedApplication().applicationIconBadgeNumber)
        
        unreadCount.producer.startWithNext { count in
            UIApplication.sharedApplication().applicationIconBadgeNumber = count
        }
        
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
        
//        refreshNotification.signal
//            .takeWhile { _ in Reachability.connectedToNetwork() && SessionService.isLoggedIn }
//            .flatMap(.Latest) { _ in
//                ApiService<Activity>.get("activities")
//                    .observeOnUserInteractive()
//                    .on(next: { activity in
//                        try! activity.insertOrUpdate()
//                        try! activity.activityResourceStar?.insertOrUpdate()
//                        activity.activityResourceStar?.optograph.insertOrIgnore()
//                        activity.activityResourceStar?.causingPerson.insertOrIgnore()
//                        try! activity.activityResourceComment?.insertOrUpdate()
//                        activity.activityResourceComment?.optograph.insertOrIgnore()
//                        activity.activityResourceComment?.comment.insertOrIgnore()
//                        activity.activityResourceComment?.causingPerson.insertOrIgnore()
//                        try! activity.activityResourceViews?.insertOrUpdate()
//                        activity.activityResourceViews?.optograph.insertOrIgnore()
//                        try! activity.activityResourceFollow?.insertOrUpdate()
//                        activity.activityResourceFollow?.causingPerson.insertOrIgnore()
//                    })
//                    .ignoreError()
//                    .collect()
//                    .startOnUserInteractive()
//            }
//            .observeOnMain()
//            .map { self.results.value.merge($0, deleteOld: false) }
//            .observeNext { results in
//                self.unreadCount.value = results.models.reduce(0) { (acc, activity) in acc + (activity.isRead ? 0 : 1) }
//                self.results.value = results
//            }
        
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

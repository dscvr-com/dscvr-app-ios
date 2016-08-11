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
//            .filter(PersonTable[PersonSchema.isFollowed] || PersonTable[PersonSchema.ID] == SessionService.personID)
//            .order(CommentSchema.createdAt.asc)
//        
//        refreshNotification.signal
//            .flatMap(.Latest) { _ in
//                DatabaseService.query(.Many, query: query)
//                    .observeOnUserInteractive()
//                    .map { row -> Activity in
//                        return Activity.fromSQL(row)
//                    }
//                    .ignoreError()
//                    .collect()
//                    .startOnUserInteractive()
//            }
//            .observeOn(UIScheduler())
//            .map { self.results.value.merge($0, deleteOld: false) }
//            .observeNext { self.results.value = $0 }
        
        refreshNotification.signal
            .takeWhile { _ in Reachability.connectedToNetwork() && SessionService.isLoggedIn }
            .flatMap(.Latest) { _ in
                ApiService<Activity>.get("activities")
                    .observeOnUserInitiated()
                    .on(next: { activity in
                        try! activity.insertOrUpdate()
                        
//                        if activity.activityResourceStar?.optograph != nil {
//                            Models.optographs.touch((activity.activityResourceStar?.optograph)!).insertOrUpdate()
//                        }
                        if activity.activityResourceStar?.causingPerson != nil {
                            Models.persons.touch((activity.activityResourceStar?.causingPerson)!).insertOrIgnore()
                        }
                        
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
                    })
                    .ignoreError()
                    .collect()
                    .startOnUserInitiated()
            }
            .observeOnMain()
            .map {self.results.value.mergeForNotification($0, deleteOld: false) }
            .observeNext { results in
                self.unreadCount.value = results.models.reduce(0) { (acc, activity) in acc + (activity.isRead ? 0 : 1) }
                self.results.value = results
            }
        refreshNotification.notify(())
        
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: #selector(ActivitiesViewModel.refresh), userInfo: nil, repeats: true)
        
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

//
//  ActivityViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/26/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class ActivitiesViewModel: NSObject {
    
    var refreshTimer: NSTimer!
    
    let results = MutableProperty<[Activity]>([])
    let unreadCount = MutableProperty<Int>(0)
    
    let refreshNotification = NotificationSignal<Void>()
    let loadMoreNotification = NotificationSignal<Void>()
    
    override init() {
        super.init()
        
//        results.value = realm.objects(Activity).sorted("createdAt", ascending: false).map(identity).subArray(20)
        
//        refreshNotificationSignal.subscribe {
//            ApiService.get("activities")
//                .map { Mapper<Activity>().mapArray($0)! }
//                .startWithNext(next: self.processModel)
//        }
//        
//        loadMoreNotificationSignal.subscribe {
//            ApiService.get("activities?offset=\(results.value.count)")
//                .map { Mapper<Activity>().mapArray($0)! }
//                .startWithNext(next: self.processModel)
//        }
        
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
    
    private func processModel(activities: [Activity]) {
//        realm.write {
//            self.realm.add(activities, update: true)
//        }
        
//        results.value = Array(Set(results.value + activities)).sort { $0.createdAt > $1.createdAt }
        unreadCount.value = results.value.reduce(0) { (acc, activity) in acc + (activity.isRead ? 0 : 1) }
    }
    
}

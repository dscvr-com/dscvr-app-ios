//
//  ActivityViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/26/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper
import RealmSwift

class ActivitiesViewModel: NSObject {
    
    let realm = try! Realm()
    
    var refreshTimer: NSTimer!
    
    let results = MutableProperty<[Activity]>([])
    let unreadCount = MutableProperty<Int>(0)
    
    let refreshNotificationSignal = NotificationSignal()
    let loadMoreNotificationSignal = NotificationSignal()
    
    override init() {
        super.init()
        
        results.value = realm.objects(Activity).sorted("createdAt", ascending: false).map(identity).subArray(20)
        
        refreshNotificationSignal.subscribe {
            Api.get("activities", authorized: true)
                .map { Mapper<Activity>().mapArray($0)! }
                .start(next: self.processApi)
        }
        
        loadMoreNotificationSignal.subscribe {
            Api.get("activities?offset=\(results.value.count)", authorized: true)
                .map { Mapper<Activity>().mapArray($0)! }
                .start(next: self.processApi)
        }
        
        refreshNotificationSignal.notify()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
    }
    
    func refresh() {
        refreshNotificationSignal.notify()
    }
    
    private func processApi(activities: [Activity]) {
        realm.write {
            self.realm.add(activities, update: true)
        }
        
        results.value = mergeModels(results.value, otherModels: activities)
        unreadCount.value = results.value.reduce(0) { (acc, activity) in acc + (activity.readByUser ? 0 : 1) }
    }
    
}

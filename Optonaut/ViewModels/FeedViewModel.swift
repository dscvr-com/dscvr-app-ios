//
//  FeedViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/23/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper
import RealmSwift

class FeedViewModel: NSObject {
    
    let realm = try! Realm()
    
    var refreshTimer: NSTimer!
    
    let results = MutableProperty<[Optograph]>([])
    let newResultsAvailable = MutableProperty<Bool>(false)
    
    let refreshNotificationSignal = NotificationSignal()
    let loadMoreNotificationSignal = NotificationSignal()
    
    override init() {
        super.init()
        
        results.value = realm.objects(Optograph).sorted("createdAt", ascending: false).map(identity).subArray(20)
        
        refreshNotificationSignal.subscribe {
            Api.get("optographs/feed", authorized: true)
                .map { Mapper<Optograph>().mapArray($0)! }
                .on(next: { optographs in
                    if let firstNew = optographs.first, firstOld = self.results.value.first {
                        self.newResultsAvailable.value = firstNew.id != firstOld.id
                    }
                })
                .start(next: self.processApi)
        }
        
        loadMoreNotificationSignal.subscribe {
            Api.get("optographs/feed?offset=\(results.value.count)", authorized: true)
                .map { Mapper<Optograph>().mapArray($0)! }
                .start(next: self.processApi)
        }
        
        refreshNotificationSignal.notify()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
    }
    
    func refresh() {
        refreshNotificationSignal.notify()
    }
    
    private func processApi(optographs: [Optograph]) {
        results.value = Array(Set(results.value + optographs)).sort { $0.createdAt > $1.createdAt }
        
        realm.write {
            self.realm.add(optographs, update: true)
        }
    }
    
}
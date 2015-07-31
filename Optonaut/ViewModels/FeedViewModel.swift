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
                    if !optographs.isEmpty && !self.results.value.isEmpty {
                        self.newResultsAvailable.value = optographs[0] != self.results.value[0]
                        print(self.newResultsAvailable.value)
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
    
    private func processApi(newOptographs: [Optograph]) {
        
        realm.write {
            self.realm.add(newOptographs, update: true)
        }
        
        let optographs = Array(Set(results.value + newOptographs))
            .sort { $0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending }
        
        print(optographs.count)
        print(optographs.map { $0.id })
        print("_____")
        
        results.value = optographs
    }
    
}
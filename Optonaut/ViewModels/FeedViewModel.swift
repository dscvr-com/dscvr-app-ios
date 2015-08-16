//
//  FeedViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/23/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class FeedViewModel: NSObject {
    
    var refreshTimer: NSTimer!
    
    let results = MutableProperty<[Optograph]>([])
    let newResultsAvailable = MutableProperty<Bool>(false)
    
    let refreshNotificationSignal = NotificationSignal()
    let loadMoreNotificationSignal = NotificationSignal()
    
    override init() {
        super.init()
        
//        results.value = realm.objects(Optograph).sorted("createdAt", ascending: false).map(identity).subArray(20)
        
        refreshNotificationSignal.subscribe {
            Api.get("optographs/feed")
                .on(next: { optograph in
                    if let firstOptograph = self.results.value.first {
                        self.newResultsAvailable.value = optograph.id != firstOptograph.id
                    }
                })
                .start(next: { optograph in
                    self.results.value.append(optograph)
                })
        }
        
        loadMoreNotificationSignal.subscribe {
            Api.get("optographs/feed?offset=\(results.value.count)")
                .start(next: { optograph in
                    self.results.value.append(optograph)
                })
        }
        
        refreshNotificationSignal.notify()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
    }
    
    func refresh() {
        refreshNotificationSignal.notify()
    }
    
    private func processApi(optographs: [Optograph]) {
//        results.value = Array(Set(results.value + optographs)).sort { $0.createdAt > $1.createdAt }
        
//        optographs.forEach { optograph in
//            optograph.save(childContext)
//        }
        for var optograph in optographs {
//            try! optograph.save(childContext)
        }
        
//        realm.write {
//            self.realm.add(optographs, update: true)
//        }
    }
    
}
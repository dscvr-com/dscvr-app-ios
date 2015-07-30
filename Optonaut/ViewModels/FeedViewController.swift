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
    let resultsLoading = MutableProperty<Bool>(false)
    let resultsLimit = MutableProperty<Int>(20)
    let newResultsAvailable = MutableProperty<Bool>(false)
    
    override init() {
        super.init()
        
        let realmResults = realm.objects(Optograph).sorted("createdAt").map(identity).subArray(resultsLimit.value)
        
        results.value = realmResults
        
        resultsLoading.producer
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil) }
            .filter(identity)
            .flatMap(.Latest) { _ in Api.get("optographs/feed", authorized: true) }
            .start(
                next: { json in
                    let optographs = Mapper<Optograph>()
                        .mapArray(json)!
                        .sort { $0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending }
                        .subArray(self.resultsLimit.value)
                    
                    self.realm.write {
                        self.realm.add(optographs, update: true)
                    }
                    
                    self.results.value = optographs
                    self.resultsLoading.value = false
                },
                error: { _ in
                    self.resultsLoading.value = false
                }
        )
        
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
    }
    
    func refresh() {
        resultsLoading.value = true
    }
    
}
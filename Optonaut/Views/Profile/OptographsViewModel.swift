//
//  OptographsTableViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/25/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class OptographsViewModel {
    
    let results = MutableProperty<TableViewResults<Optograph>>(.empty())
    
    let refreshNotification = NotificationSignal<Void>()
    let loadMoreNotification = NotificationSignal<Void>()
    
    init(personID: UUID) {
        
//        let queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
//        
//        let query = OptographTable
//            .select(*)
//            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
//            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
//            .filter(PersonTable[PersonSchema.ID] == personID)
        
//        refreshNotification.signal
//            .flatMap(.Latest) { _ in
//                DatabaseService.query(.Many, query: query)
//                    .observeOn(QueueScheduler(queue: queue))
//                    .map { row -> Optograph in
//                        var optograph = Optograph.fromSQL(row)
//                        
//                        optograph.person = Person.fromSQL(row)
//                        optograph.location = row[OptographSchema.locationID] == nil ? nil : Location.fromSQL(row)
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
//        
//        refreshNotification.signal
//            .mapError { _ in ApiError.Nil }
//            .flatMap(.Latest) { _ in
//                ApiService<Optograph>.get("persons/\(personID)/optographs")
//                    .observeOn(QueueScheduler(queue: queue))
//                    .on(next: { optograph in
//                        try! optograph.insertOrUpdate()
//                        try! optograph.location?.insertOrUpdate()
//                        try! optograph.person.insertOrUpdate()
//                    })
//                    .collect()
//                    .startOn(QueueScheduler(queue: queue))
//            }
//            .observeOn(UIScheduler())
//            .map { self.results.value.merge($0, deleteOld: false) }
//            .observeNext { self.results.value = $0 }
//        
//        loadMoreNotification.signal
//            .mapError { _ in ApiError.Nil }
//            .map { _ in self.results.value.models.last }
//            .ignoreNil()
//            .flatMap(.Latest) { oldestResult in
//                ApiService<Optograph>.get("persons/\(personID)/optographs", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
//                    .observeOn(QueueScheduler(queue: queue))
//                    .on(next: { optograph in
//                        try! optograph.insertOrUpdate()
//                        try! optograph.location?.insertOrUpdate()
//                        try! optograph.person.insertOrUpdate()
//                    })
//                    .collect()
//                    .startOn(QueueScheduler(queue: queue))
//            }
//            .observeOn(UIScheduler())
//            .map { self.results.value.merge($0, deleteOld: false) }
//            .observeNext { self.results.value = $0 }
    }
    
}
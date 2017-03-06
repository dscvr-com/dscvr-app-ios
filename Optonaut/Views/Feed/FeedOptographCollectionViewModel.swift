//
//  FeedViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/23/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite
import SwiftyUserDefaults

class FeedOptographCollectionViewModel: OptographCollectionViewModel {
    
    private var refreshTimer: NSTimer?
    
    let results = MutableProperty<TableViewResults<Optograph>>(.empty())
    let isActive = MutableProperty<Bool>(false)
    
    private let refreshNotification = NotificationSignal<Void>()
    
    init() {
        
        let query = OptographTable.select(*)
            .filter(OptographTable[OptographSchema.isInFeed] && OptographTable[OptographSchema.deletedAt] == nil)
            .order(OptographTable[OptographSchema.createdAt].asc)
        
        refreshNotification.signal
            .flatMap(.Latest) { _ in
                DatabaseService.query(.Many, query: query)
                    .observeOnUserInteractive()
                    .on(next: { row in
                        Models.optographs.touch(Optograph.fromSQL(row))
                    })
                    .map(Optograph.fromSQL)
                    .ignoreError()
                    .collect()
                    .startOnUserInteractive()
            }   
            .observeOnMain()
            .map {self.results.value.merge($0, deleteOld: false) }
            .observeNext { self.results.value = $0 }
        
//        refreshNotification.signal
//            .takeWhile { _ in Reachability.connectedToNetwork() }
//            .flatMap(.Latest) { _ in
//                ApiService<OptographApiModel>.get("optographs/feed")
//                    .observeOnUserInitiated()
//                    .on(next: { apiModel in
//                        Models.optographs.touch(apiModel).insertOrUpdate { box in
//                            box.model.isInFeed = true
//                            box.model.isStitched = true
//                            box.model.isPublished = true
//                            box.model.isSubmitted = true
//                        }
//                    })
//                    .map(Optograph.fromApiModel)
//                    .ignoreError()
//                    .collect()
//                    .startOnUserInitiated()
//            }
//            .observeOnMain()
//            .map { self.results.value.merge($0, deleteOld: false) }
//            .observeNext { results in
//                self.results.value = results
//        }
 
        
        isActive.producer.skipRepeats().startWithNext { [weak self] isActive in
            if isActive {
                self?.refresh()
            } else {
                self?.refreshTimer?.invalidate()
            }
        }
        
        PipelineService.stitchingStatus.producer
            .startWithNext { [weak self] status in
                if case .StitchingFinished(_) = status {
                    self?.refresh()
                }
        }
    }
    
    func refresh() {
        refreshNotification.notify(())
    }
    
}
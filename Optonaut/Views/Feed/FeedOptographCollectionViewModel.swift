//
//  FeedViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/23/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveSwift
import SQLite
import SwiftyUserDefaults

class FeedOptographCollectionViewModel: OptographCollectionViewModel {
    
    fileprivate var refreshTimer: Timer?
    
    let results = MutableProperty<TableViewResults<Optograph>>(.empty())
    let isActive = MutableProperty<Bool>(false)
    
    fileprivate let refreshNotification = NotificationSignal<Void>()
    
    init() {
        
        let query = OptographTable.select(*)
            .filter(OptographTable[OptographSchema.isInFeed] && OptographTable[OptographSchema.deletedAt] == nil)
            .order(OptographTable[OptographSchema.createdAt].asc)
        
        refreshNotification.signal
            .flatMap(.latest) { _ in
                DatabaseService.query(.many, query: query)
                    .observeOnUserInteractive()
                    .on(value: { row in
                        Models.optographs.touch(Optograph.fromSQL(row))
                    })
                    .map(Optograph.fromSQL)
                    .ignoreError()
                    .collect()
                    .startOnUserInteractive()
            }   
            .observeOnMain()
            .map {self.results.value.merge($0, deleteOld: false) }
            .observeValues { self.results.value = $0 }
        
        isActive.producer.skipRepeats().startWithValues { [weak self] isActive in
            if isActive {
                self?.refresh()
            } else {
                self?.refreshTimer?.invalidate()
            }
        }
        
        PipelineService.stitchingStatus.producer
            .startWithValues { [weak self] status in
                if case .stitchingFinished(_) = status {
                    self?.refresh()
                }
        }
    }
    
    func refresh() {
        refreshNotification.notify(())
    }
    
}

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
    
    let results = MutableProperty<[Optograph]>([Optograph]())
    let isActive = MutableProperty<Bool>(false)
    
    fileprivate let refreshNotification = NotificationSignal<Void>()
    
    init() {
        
        refreshNotification.signal
            .observe { _ in
                self.results.value = DataBase.sharedInstance.getOptographs()
                    .filter{ $0.deletedAt == nil && $0.isStitched }
                    .sorted{ $0.createdAt > $1.createdAt }
        }
        
        
        PipelineService.stitchingStatus.producer
            .startWithValues { [weak self] status in
                if case .stitchingFinished(_) = status {
                    self?.refresh()
                }
        }
        
        refresh()
    }
    
    func getOptographIds() -> [UUID] {
        return self.results.value.map { $0.ID }
    }
    
    func refresh() {
        refreshNotification.notify(())
    }
    
}

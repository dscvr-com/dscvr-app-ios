//
//  StorytellingVCModel.swift
//  DSCVR
//
//  Created by robert john alkuino on 10/13/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite



class StorytellingVCModel {

    let refreshNotification = NotificationSignal<Void>()
    let results = MutableProperty<[Story]>([])
    let isActive = MutableProperty<Bool>(false)
    private var refreshTimer: NSTimer?
    
    init(personID: UUID) {
        
        let query = StoryTable
            .select(*)
            .join(OptographTable, on: StoryTable[StorySchema.optographID] == OptographTable[OptographSchema.ID])
            .join(PersonTable, on: StoryTable[StorySchema.personID] == PersonTable[PersonSchema.ID])
            .filter(StoryTable[StorySchema.personID] == personID)
        
        refreshNotification.signal
            .flatMap(.Latest) { _ in
                DatabaseService.query(.Many, query: query)
                    .observeOnUserInteractive()
                    .on(next: { row in
                        Models.optographs.touch(Optograph.fromSQL(row))
                        Models.persons.touch(Person.fromSQL(row))
                        Models.story.touch(Story.fromSQL(row))
//                        if apiModel.story.children!.count != 0 {
//                            for child in apiModel.story.children! {
//                                Models.storyChildren.touch(child).insertOrUpdate()
//                            }
//                        }
                    })
                    .map(Story.fromSQL)
                    .ignoreError()
                    .collect()
                    .startOnUserInteractive()
            }
            .observeOnMain()
            .observeNext {self.results.value = $0 }
        
        isActive.producer.skipRepeats().startWithNext { [weak self] isActive in
            if isActive {
                self?.refresh()
            } else {
                self?.refreshTimer?.invalidate()
            }
        }
    }
    
    func refresh() {
        refreshNotification.notify(())
    }
}


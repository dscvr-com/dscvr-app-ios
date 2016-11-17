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
    
    init(personID: UUID) {
        
        let query = StoryTable
            .select(*)
            .join(OptographTable, on: StoryTable[StorySchema.optographID] == OptographTable[OptographSchema.ID])
            .join(PersonTable, on: StoryTable[StorySchema.personID] == PersonTable[PersonSchema.ID])
            .filter(StoryTable[StorySchema.personID] == personID && StoryTable[StorySchema.deletedAt] == nil)
        
        refreshNotification.signal
            .takeWhile { _ in SessionService.isLoggedIn }
            .flatMap(.Latest) { _ in
                DatabaseService.query(.Many, query: query)
                    .observeOnUserInteractive()
                    .on(next: { row in
                        Models.optographs.touch(Optograph.fromSQL(row))
                        Models.persons.touch(Person.fromSQL(row))
                        Models.story.touch(Story.fromSQL(row))
                        
                    })
                    .map(Story.fromSQL)
                    .ignoreError()
                    .collect()
                    .startOnUserInteractive()
            }
            .observeOnMain()
            .observeNext {self.results.value = $0 }
    }
}


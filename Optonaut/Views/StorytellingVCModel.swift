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
        
//        refreshNotification.signal
//            .takeWhile { _ in Reachability.connectedToNetwork() }
//            .flatMap(.Latest) { _ in
//                ApiService<OptographApiModel>.getForGate("story/merged/\(SessionService.personID)")
//                    .observeOnUserInitiated()
//                    .on(next: { apiModel in
//                        Models.optographs.touch(apiModel).insertOrUpdate { box in
//                            box.model.isInFeed = true
//                            box.model.isStitched = true
//                            box.model.isPublished = true
//                            box.model.isSubmitted = true
//                            box.model.starsCount = apiModel.starsCount
//                        }
//                        Models.persons.touch(apiModel.person).insertOrUpdate { ps in
//                            ps.model.isFollowed = apiModel.person.isFollowed
//                        }
//                        Models.locations.touch(apiModel.location)?.insertOrUpdate()
//                        
//                        Models.story.touch(apiModel.story).insertOrUpdate()
//                        
//                        if apiModel.story.children!.count != 0 {
//                            for child in apiModel.story.children! {
//                                Models.storyChildren.touch(child).insertOrUpdate()
//                            }
//                        }
//                        
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
    }
}


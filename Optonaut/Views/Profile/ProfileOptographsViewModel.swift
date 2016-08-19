//
//  ProfileOptographsViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 28/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class ProfileOptographsViewModel {
    
    let results = MutableProperty<TableViewResults<Optograph>>(.empty())
    
    let refreshNotification = NotificationSignal<Void>()
    let loadMoreNotification = NotificationSignal<Void>()
    let isActive = MutableProperty<Bool>(false)
    
    init(personID: UUID) {
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .filter(PersonTable[PersonSchema.ID] == personID)
        
        refreshNotification.signal
            .flatMap(.Latest) { _ in
                DatabaseService.query(.Many, query: query)
                    .observeOnUserInteractive()
                    .map { row -> Optograph in
                        let optograph = Optograph.fromSQL(row)
                        Models.optographs.touch(optograph)
                        Models.persons.touch(Person.fromSQL(row))
                        if !Reachability.connectedToNetwork() {
                            Models.locations.touch(row[OptographSchema.locationID] != nil ? Location.fromSQL(row) : nil)
                        }
                        
//
//                        if row[OptographSchema.locationID] != nil {
//                            if Models.locations[row[OptographSchema.locationID]] == nil {
//                                print("Walang location!")
//                                Models.optographs.touch(optograph).insertOrUpdate { box in
//                                    box.model.locationID = nil
//                                }
//                                Models.locations.touch(nil)
//                            } else {
//                                Models.locations.touch(Location.fromSQL(row))
//                            }
//                        } else {
//                            Models.locations.touch(nil)
//                        }
                        
                        
                        return optograph
                    }
                    .ignoreError()
                    .collect()
                    .startOnUserInteractive()
            }
            .observeOnMain()
            .map { self.results.value.merge($0, deleteOld: false) }
            .observeNext { self.results.value = $0 }

        refreshNotification.signal
            .takeWhile { _ in Reachability.connectedToNetwork() }
            .flatMap(.Latest) { _ in
                ApiService<OptographApiModel>.get("persons/\(personID)/optographs")
                    .observeOnUserInitiated()
                    .on(next: { apiModel in
                        Models.optographs.touch(apiModel).insertOrUpdate { box in
                            box.model.isStitched = true
                            box.model.isPublished = true
                            box.model.isSubmitted = true
                            box.model.starsCount = apiModel.starsCount
                        }
                        Models.persons.touch(apiModel.person).insertOrUpdate()
                        Models.locations.touch(apiModel.location)?.insertOrUpdate()
                    })
                    .map(Optograph.fromApiModel)
                    .ignoreError()
                    .collect()
                    .startOnUserInitiated()
            }
            .observeOnMain()
            .map { self.results.value.merge($0, deleteOld: false) }
            .observeNext { self.results.value = $0 }
        
        
        loadMoreNotification.signal
            .takeWhile { _ in Reachability.connectedToNetwork() }
            .map { _ in self.results.value.models.last }
            .ignoreNil()
            .flatMap(.Latest) { oldestResult in
                ApiService<OptographApiModel>.get("persons/\(personID)/optographs", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
                    .observeOnUserInitiated()
                    .on(next: { apiModel in
                        Models.optographs.touch(apiModel).insertOrUpdate { box in
                            box.model.isStitched = true
                            box.model.isPublished = true
                            box.model.isSubmitted = true
                        }
                        Models.persons.touch(apiModel.person).insertOrUpdate()
                        Models.locations.touch(apiModel.location)?.insertOrUpdate()
                    })
                    .map(Optograph.fromApiModel)
                    .ignoreError()
                    .collect()
                    .startOnUserInitiated()
            }
            .observeOnMain()
            .map { self.results.value.merge($0, deleteOld: false) }
            .observeNext { self.results.value = $0 }
    }
    
    func refresh() {
        refreshNotification.notify(())
    }
}
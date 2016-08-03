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
                        
                        if row[OptographSchema.locationID] != nil {
                            Models.locations.touch(Location.fromSQL(row))
                        }
                        
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
                    //.filter({ return $0.deletedAt == nil })
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
        
        loadMoreNotification.signal
            .takeWhile { _ in Reachability.connectedToNetwork() }
            .map { _ in self.results.value.models.last }
            .ignoreNil()
            .flatMap(.Latest) { oldestResult in
                ApiService<OptographApiModel>.get("persons/\(personID)/optographs", queries: ["older_than": oldestResult.createdAt.toRFC3339String()])
                    .observeOnUserInitiated()
                    //.filter({ $0.deletedAt == nil })
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
    
    func createLocationWhenNil() {
    
    }
}
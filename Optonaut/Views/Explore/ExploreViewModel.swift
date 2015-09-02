//
//  ExploreViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class ExploreViewModel {
    
    let results = MutableProperty<[Optograph]>([])
    let resultsLoading = MutableProperty<Bool>(false)
    
    init() {
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
        
        let optographs = DatabaseManager.defaultConnection.prepare(query).map { row -> Optograph in
            let person = Person.fromSQL(row)
            let location = Location.fromSQL(row)
            var optograph = Optograph.fromSQL(row)
            
            optograph.person = person
            optograph.location = location
            
            return optograph
        }
        
        results.value = optographs.sort { $0.createdAt > $1.createdAt }
        
        resultsLoading.producer
            .mapError { _ in ApiError.Nil }
            .filter { $0 }
            .flatMap(.Latest) { _ in ApiService.get("optographs") }
            .start(
                next: processNewOptograph,
                completed: {
                    self.resultsLoading.value = false
                },
                error: { _ in
                    self.resultsLoading.value = false
                }
        )
    }
    
    private func processNewOptograph(optograph: Optograph) {
        results.value.orderedInsert(optograph, withOrder: .OrderedDescending)
        
        try! optograph.insertOrReplace()
        try! optograph.location.insertOrReplace()
        try! optograph.person.insertOrReplace()
    }
    
}
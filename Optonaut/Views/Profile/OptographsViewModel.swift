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
    
    let id: ConstantProperty<UUID>
    let results = MutableProperty<[Optograph]>([])
    let resultsLoading = MutableProperty<Bool>(false)
    
    init(personId: UUID) {
        id = ConstantProperty(personId)
    }
    
    func reload() {
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(PersonTable[PersonSchema.id] == id.value)
        
        DatabaseService.defaultConnection.prepare(query)
            .map({ row -> Optograph in
                let person = Person.fromSQL(row)
                let location = Location.fromSQL(row)
                var optograph = Optograph.fromSQL(row)
                
                optograph.person = person
                optograph.location = location
                
                return optograph
            })
            .forEach(processNewOptograph)
        
        resultsLoading.producer
            .mapError { _ in ApiError.Nil }
            .filter { $0 }
            .flatMap(.Latest) { _ in ApiService<Optograph>.get("persons/\(self.id.value)/optographs") }
            .on(
                next: { optograph in
                    self.processNewOptograph(optograph)
                    
                    try! optograph.insertOrReplace()
                    try! optograph.location.insertOrReplace()
                    try! optograph.person.insertOrReplace()
                },
                completed: {
                    self.resultsLoading.value = false
                },
                error: { _ in
                    self.resultsLoading.value = false
                }
            )
            .start()
    }
    
    private func processNewOptograph(optograph: Optograph) {
        results.value.orderedInsert(optograph, withOrder: .OrderedDescending)
        results.value.filterDeleted()
    }
    
}
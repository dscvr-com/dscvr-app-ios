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
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(PersonTable[PersonSchema.id] == personId)
        
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
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil) }
            .filter { $0 }
            .flatMap(.Latest) { _ in ApiService.get("persons/\(personId)/optographs") }
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
        
        try! DatabaseManager.defaultConnection.run(PersonTable.insert(or: .Replace, optograph.person.toSQL()))
        try! DatabaseManager.defaultConnection.run(LocationTable.insert(or: .Replace, optograph.location.toSQL()))
        try! DatabaseManager.defaultConnection.run(OptographTable.insert(or: .Replace, optograph.toSQL()))
    }
    
}

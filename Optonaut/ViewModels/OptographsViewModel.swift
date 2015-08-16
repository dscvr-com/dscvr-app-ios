//
//  OptographsTableViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/25/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class OptographsViewModel {
    
    let id: ConstantProperty<Int>
    let results = MutableProperty<[Optograph]>([])
    let resultsLoading = MutableProperty<Bool>(false)
    
    init(personId: Int) {
        id = ConstantProperty(personId)
        
//        if let person = realm.objectForPrimaryKey(Person.self, key: personId) {
//            results.value = person.optographs.map(identity)
//        }
        
        resultsLoading.producer
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil) }
            .filter { $0 }
            .flatMap(.Latest) { _ in Api.get("persons/\(personId)/optographs") }
            .start(
                next: { optograph in
                    self.results.value.append(optograph)
//                    self.results.value = self.results.value.sort { $0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending }
                },
                completed: {
                    self.resultsLoading.value = false
                },
                error: { _ in
                    self.resultsLoading.value = false
                }
        )
        
    }
    
}

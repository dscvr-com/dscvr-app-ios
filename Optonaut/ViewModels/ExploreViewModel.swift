//
//  ExploreViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper
import RealmSwift

class ExploreViewModel {
    
    let realm = try! Realm()
    
    let results = MutableProperty<[Optograph]>([])
    let resultsLoading = MutableProperty<Bool>(false)
    
    init() {
        
        resultsLoading.producer
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil) }
            .filter { $0 }
            .flatMap(.Latest) { _ in Api.get("optographs", authorized: true) }
            .start(
                next: { json in
                    let optographs = Mapper<Optograph>()
                        .mapArray(json)!
                        .sort { $0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending }
                    
                    self.results.value = optographs
                    self.resultsLoading.value = false
                },
                error: { _ in
                    self.resultsLoading.value = false
                }
        )
        
    }
    
}
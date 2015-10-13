//
//  OptographsTableViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/25/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class SearchViewModel {
    
    let results = MutableProperty<[Optograph]>([])
    let searchText = MutableProperty<String>("")
    
    init() {
        searchText.producer
            .mapError { _ in ApiError.Nil }
            .filter { $0.characters.count > 2 }
            .throttle(0.3, onScheduler: QueueScheduler.mainQueueScheduler)
            .map(escape)
            .flatMap(.Latest) { keyword in
                return ApiService<Optograph>.get("optographs/search?keyword=\(keyword)")
                    .on(next: { optograph in
                        try! optograph.insertOrUpdate()
                        try! optograph.location.insertOrUpdate()
                        try! optograph.person.insertOrUpdate()
                    })
                    .collect()
            }
            .startWithNext { optographs in
                self.results.value = optographs
            }
    }
    
    private func escape(str: String) -> String {
        return str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
    
}

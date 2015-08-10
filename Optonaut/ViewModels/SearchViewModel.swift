//
//  OptographsTableViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/25/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper

class SearchViewModel {
    
    let results = MutableProperty<[Optograph]>([])
    let searchText = MutableProperty<String>("")
    
    init() {
        searchText.producer
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil)}
            .filter { $0.characters.count > 2 }
            .throttle(0.3, onScheduler: QueueScheduler.mainQueueScheduler)
            .map(escape)
            .flatMap(.Latest) { keyword in Api.get("optographs/search?keyword=\(keyword)", authorized: true) }
            .map { json in Mapper<Optograph>().mapArray(json)! }
            .start(next: { optographs in
                self.results.value = optographs.sort { $0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending }
            })
    }
    
    private func escape(str: String) -> String {
        return str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
    
}

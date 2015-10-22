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
    
    let results = MutableProperty<TableViewResults>(.empty)
    let hashtags = MutableProperty<[Hashtag]>([])
    let searchText = MutableProperty<String>("")
    
    init() {
        let queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
        searchText.producer
            .on(next: { str in
                if str.isEmpty {
                    self.results.value = .empty
                }
            })
            .filter { $0.characters.count > 2 }
            .throttle(0.3, onScheduler: QueueScheduler(queue: queue))
            .map(removeHashtag)
            .map(escape)
            .flatMap(.Latest) { keyword in
                return ApiService<Optograph>.get("optographs/search?keyword=\(keyword)")
                    .on(next: { optograph in
                        try! optograph.insertOrUpdate()
                        try! optograph.location.insertOrUpdate()
                        try! optograph.person.insertOrUpdate()
                    })
                    .ignoreError()
                    .collect()
                    .startOn(QueueScheduler(queue: queue))
            }
            .observeOn(UIScheduler())
            .map { mergeResults($0, oldOptographs: self.results.value.optographs, deleteOld: true) }
            .startWithNext { self.results.value = $0 }
        
        ApiService<Hashtag>.get("hashtags/popular")
            .collect()
            .startWithNext { self.hashtags.value = $0 }
    }
    
    private func escape(str: String) -> String {
        return str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
    
    private func removeHashtag(str: String) -> String {
        let index = str.startIndex.advancedBy(1)
        if str.substringToIndex(index) == "#" {
            return str.substringFromIndex(index)
        } else {
            return str
        }
    }
    
}

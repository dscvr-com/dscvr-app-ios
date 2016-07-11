//
//  SearchTableModel.swift
//  Iam360
//
//  Created by robert john alkuino on 6/9/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class SearchTableModel {
    
    let results = MutableProperty<[Person]>([])
    let searchText = MutableProperty<String>("")
    private var personBox: ModelBox<Person>!
    
    init() {
        let queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
                searchText.producer
                    .on(next: { str in
                        if str.isEmpty {
                            self.results.value = []
                        }
                    })
                    .filter { $0.characters.count > 2 }
                    .throttle(0.3, onScheduler: QueueScheduler(queue: queue))
                    .map(escape)
                    .flatMap(.Latest) { keyword in
                        return ApiService<PersonApiModel>.get("persons/search?keyword=\(keyword)")
                            .on(next: { apiModel in
                                Models.persons.touch(apiModel).insertOrUpdate()
                            })
                            .ignoreError()
                            .map(Person.fromApiModel)
                            .collect()
                            .startOn(QueueScheduler(queue: queue))
                    }
                    .observeOn(UIScheduler())
                    .startWithNext { self.results.value = $0 }
        
//        ApiService<Hashtag>.get("hashtags/popular")
//            .collect()
//            .startWithNext { self.hashtags.value = $0 }
    }
    
    private func escape(str: String) -> String {
        return str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
    }
}

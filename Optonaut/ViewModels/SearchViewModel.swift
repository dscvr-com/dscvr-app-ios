//
//  OptographsTableViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/25/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SwiftyJSON

class SearchViewModel {
    
    let results = MutableProperty<[Optograph]>([])
    let searchText = MutableProperty<String>("")
    
    init() {
        let keywordToJson: SignalProducer<String, NSError>  -> SignalProducer<JSON, NSError> = flatMap(.Latest) { keyword in Api().get("optographs/search?keyword=\(keyword)", authorized: true) }
        
        searchText.producer
            |> mapError { _ in NSError() }
            |> filter { count($0) > 2 }
            |> throttle(0.3, onScheduler: QueueScheduler.mainQueueScheduler)
            |> keywordToJson
            |> start(
                next: { jsonArray in
                    var optographs = jsonArray.arrayValue.map(mapOptographFromJson)
                    optographs.sort { $0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending }
                    
                    self.results.put(optographs)
                }
        )
        
    }
    
}

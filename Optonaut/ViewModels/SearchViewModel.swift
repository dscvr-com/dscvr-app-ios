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
import ObjectMapper

class SearchViewModel {
    
    let results = MutableProperty<[Optograph]>([])
    let searchText = MutableProperty<String>("")
    
    init() {
        let keywordToJson: SignalProducer<String, NSError>  -> SignalProducer<JSON, NSError> = flatMap(.Latest) { keyword in
            let escapedKeyword = keyword.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
            return Api.get("optographs/search?keyword=\(escapedKeyword!)", authorized: true)
        }
        
        searchText.producer
            |> mapError { _ in NSError(domain: "", code: 0, userInfo: nil)}
            |> filter { $0.characters.count > 2 }
            |> throttle(0.3, onScheduler: QueueScheduler.mainQueueScheduler)
            |> keywordToJson
            |> start(
                next: { jsonArray in
                    var optographs = Mapper<Optograph>().mapArray(jsonArray.rawValue)!
                    optographs = optographs.sort { $0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending }
                    
                    self.results.put(optographs)
                }
        )
        
    }
    
}

//
//  ActivityViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/26/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper

class ActivitiesViewModel {
    
    let results = MutableProperty<[Activity]>([])
    let resultsLoading = MutableProperty<Bool>(false)
    
    init() {
        let callApi: SignalProducer<Bool, NSError> -> SignalProducer<JSONResponse, NSError> = flatMap(.Latest) { _ in Api.get("activities", authorized: true) }
        
        resultsLoading.producer
            |> mapError { _ in NSError(domain: "", code: 0, userInfo: nil) }
            |> filter { $0 }
            |> callApi
            |> start(
                next: { json in
                    var activities = Mapper<Activity>().mapArray(json)!
                    activities = activities.sort { $0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending }
                    
                    self.results.put(activities)
                    self.resultsLoading.put(false)
                },
                error: { _ in
                    self.resultsLoading.put(false)
                }
        )
        
    }
    
}

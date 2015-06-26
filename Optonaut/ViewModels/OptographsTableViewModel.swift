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

class OptographsTableViewModel {
    
    let results = MutableProperty<[Optograph]>([])
    let resultsLoading = MutableProperty<Bool>(false)
    
    init(source: String) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"
        
        resultsLoading.producer
            |> filter { $0 }
            |> map { _ in Api().get(source, authorized: true) }
            |> start(
                next: { signal in
                    signal
                        |> observe(
                            next: { jsonArray in
                                var optographs = [Optograph]()
                                
                                for (_, optographJson): (String, JSON) in jsonArray {
                                    let user = User()
                                    user.id = optographJson["user"]["id"].intValue
                                    user.email = optographJson["user"]["email"].stringValue
                                    user.userName = optographJson["user"]["user_name"].stringValue
                                    
                                    let optograph = Optograph()
                                    optograph.id = optographJson["id"].intValue
                                    optograph.text = optographJson["text"].stringValue
                                    optograph.numberOfLikes = optographJson["number_of_likes"].intValue
                                    optograph.likedByUser = optographJson["liked_by_user"].boolValue
                                    optograph.createdAt = dateFormatter.dateFromString(optographJson["created_at"].stringValue)!
                                    optograph.user = user
                                    
                                    optographs.append(optograph)
                                }
                                
                                optographs.sort{ $0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending }
                                
                                self.results.put(optographs)
                                self.resultsLoading.put(false)
                            },
                            error: { error in
                                println(error)
                                self.resultsLoading.put(false)
                            }
                    )
                }
        )
        
//        let signal = Api().get("optographs", authorized: true)
        
//        signal
//            |> observe(
//                next: { jsonArray in
//                    var optographs = [Optograph]()
//                    
//                    for (_, optographJson): (String, JSON) in jsonArray {
//                        let user = User()
//                        user.id = optographJson["user"]["id"].intValue
//                        user.email = optographJson["user"]["email"].stringValue
//                        user.userName = optographJson["user"]["user_name"].stringValue
//                        
//                        let optograph = Optograph()
//                        optograph.id = optographJson["id"].intValue
//                        optograph.text = optographJson["text"].stringValue
//                        optograph.numberOfLikes = optographJson["number_of_likes"].intValue
//                        optograph.likedByUser = optographJson["liked_by_user"].boolValue
//                        optograph.createdAt = dateFormatter.dateFromString(optographJson["created_at"].stringValue)!
//                        optograph.user = user
//                        
//                        optographs.append(optograph)
//                    }
//                    
//                    self.results.put(optographs)
//                },
//                error: { error in
//                    println(error)
//                }
//        )
    }
    
}

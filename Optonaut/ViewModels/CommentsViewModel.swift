//
//  CommentsViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper

class CommentsViewModel {
    
    let results = MutableProperty<[Comment]>([])
    
    init(optographId: Int) {
        
        Api.get("optographs/\(optographId)/comments", authorized: true)
            .map { json in Mapper<Comment>().mapArray(json)! }
            .start(next: { comments in
                self.results.value = comments
                
//                self.realm.write {
//                    self.realm.add(comments, update: true)
//                }
            })
        
    }
}
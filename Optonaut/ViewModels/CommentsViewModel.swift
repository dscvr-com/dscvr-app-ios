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
import RealmSwift

class CommentsViewModel {
    
    let realm = try! Realm()
    
    let optographId: ConstantProperty<Int>
    let results = MutableProperty<[Comment]>([])
    
    init(optographId: Int) {
        self.optographId = ConstantProperty(optographId)
        
        let predicate = NSPredicate(format: "optograph.id = %i", optographId)
        results.value = realm
            .objects(Comment)
            .sorted("createdAt", ascending: false)
            .filter(predicate)
            .map(identity)
            .subArray(20)
        
        Api.get("optographs/\(optographId)/comments", authorized: true)
            .map { json in Mapper<Comment>().mapArray(json)! }
            .start(next: { comments in
                self.results.value = comments
                
                if let optograph = self.realm.objectForPrimaryKey(Optograph.self, key: optographId) {
                    for comment in comments {
                        comment.optograph = optograph
                    }
                }
                
                self.realm.write {
                    self.realm.add(comments, update: true)
                }
            })
        
    }
}
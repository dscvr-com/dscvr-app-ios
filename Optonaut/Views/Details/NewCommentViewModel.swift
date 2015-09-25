//
//  NewCommentViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class NewCommentViewModel {
    
    let optographId: ConstantProperty<UUID>
    let text = MutableProperty<String>("")
    let postingEnabled = MutableProperty<Bool>(false)
    let isPosting = MutableProperty<Bool>(false)
    let commentsCount = MutableProperty<Int>(0)
    
    init(optographId: UUID, commentsCount: Int) {
        self.optographId = ConstantProperty(optographId)
        self.commentsCount.value = commentsCount
        
        postingEnabled <~ text.producer.map(isNotEmpty)
            .combineLatestWith(isPosting.producer.map(negate)).map(and)
    }
    
    func postComment() -> SignalProducer<Comment, ApiError> {
        return ApiService.post("optographs/\(optographId.value)/comments", parameters: ["text": text.value])
            .on(
                started: {
                    self.isPosting.value = true
                    self.commentsCount.value++
                },
                next: { comment in
                    try! comment.person.insertOrReplace()
                    try! comment.insertOrReplace()
                },
                completed: {
                    self.text.value = ""
                    self.isPosting.value = false
                },
                error: { _ in
                    self.commentsCount.value--
                }
        )
    }
    
}
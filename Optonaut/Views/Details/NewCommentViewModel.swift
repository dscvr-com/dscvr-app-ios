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
    let isValid = MutableProperty<Bool>(false)
    let isPosting = MutableProperty<Bool>(false)
    
    init(optographId: UUID) {
        self.optographId = ConstantProperty(optographId)
        
        text.producer.map { !$0.isEmpty }.startWithNext { self.isValid.value = $0 }
    }
    
    func postComment() -> SignalProducer<Comment, ApiError> {
        return ApiService.post("optographs/\(optographId.value)/comments", parameters: ["text": text.value])
            .on(
                started: {
                    self.isPosting.value = true
                },
                next: { comment in
                    try! comment.person.insertOrUpdate()
                    try! comment.insertOrUpdate()
                },
                completed: {
                    self.text.value = ""
                    self.isPosting.value = false
                }
        )
    }
    
}
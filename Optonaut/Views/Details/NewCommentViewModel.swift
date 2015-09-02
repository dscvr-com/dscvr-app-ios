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
    
    init(optographId: UUID) {
        self.optographId = ConstantProperty(optographId)
        
        text.producer
            .map { !$0.isEmpty }
            .start(next: { self.isValid.value = $0 })
    }
    
    func postComment() -> SignalProducer<Comment, ApiError> {
        return ApiService.post("optographs/\(optographId.value)/comments", parameters: ["text": text.value])
            .on(
                next: { comment in
                    try! comment.person.insertOrReplace()
                    try! comment.insertOrReplace()
                },
                completed: {
                    self.text.value = ""
                }
        )
    }
    
}
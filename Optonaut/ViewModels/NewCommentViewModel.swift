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
    
    func postComment() -> SignalProducer<Comment, NSError> {
        let parameters = ["text": text.value]
        return Api.post("optographs/\(optographId.value)/comments", parameters: parameters)
            .on(completed: {
                self.text.value = ""
            })
    }
    
}
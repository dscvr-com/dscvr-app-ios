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
    
    let optographId: ConstantProperty<Int>
    let text = MutableProperty<String>("")
    let isValid = MutableProperty<Bool>(false)
    
    init(optographId: Int) {
        self.optographId = ConstantProperty(optographId)
        
        text.producer
            .map { !$0.isEmpty }
            .start(next: { self.isValid.value = $0 })
    }
    
    func postComment() -> SignalProducer<JSONResponse, NSError> {
        let parameters = ["text": text.value]
        return Api.post("optographs/\(optographId.value)/comments", authorized: true, parameters: parameters)
            .on(completed: {
                self.text.value = ""
            })
    }
    
}
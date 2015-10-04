//
//  ForgotPasswordViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class ForgotPasswordViewModel {
    
    let email = MutableProperty<String>("")
    let emailValid = MutableProperty<Bool>(false)
    let pending = MutableProperty<Bool>(false)
    
    init() {
        email.producer.startWithNext { str in
            self.emailValid.value = isValidEmail(str)
        }
    }
    
    func sendEmail() -> SignalProducer<EmptyResponse, ApiError> {
        pending.value = true
        
        let parameters = ["email": email.value]
        return ApiService.post("persons/forgot-password", parameters: parameters)
            .on(
                completed: { _ in
                    self.pending.value = false
                },
                error: { _ in
                    self.pending.value = false
                }
        )
    }
    
}
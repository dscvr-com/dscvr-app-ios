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
    let emailStatus = MutableProperty<LineTextField.Status>(.Indicated)
    let pending = MutableProperty<Bool>(false)
    let sent = MutableProperty<Bool>(false)
    
    init() {
        emailStatus <~ email.producer.map(isValidEmail).map { $0 ? .Normal : .Indicated }
    }
    
    func sendEmail() -> SignalProducer<EmptyResponse, ApiError> {
        pending.value = true
        
        let parameters = ["email": email.value]
        return ApiService.post("persons/forgot-password", parameters: parameters)
            .on(
                completed: { [weak self] _ in
                    self?.pending.value = false
                    self?.sent.value = true
                },
                error: { [weak self] _ in
                    self?.pending.value = false
                }
        )
    }
    
}
//
//  RequestInviteViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/6/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class RequestInviteViewModel {
    
    let email = MutableProperty<String>("")
    let emailValid = MutableProperty<Bool>(false)
    let pending = MutableProperty<Bool>(false)
    
    init() {
        email.producer
            |> start(next: { str in
                self.emailValid.put(isValidEmail(str))
            })
    }
    
    func requestInvite() -> SignalProducer<Void, NSError> {
        return SignalProducer { sink, disposable in
            self.pending.put(true)
            
            let parameters = ["email": self.email.value]
            Api.post("users/request-invite", authorized: false, parameters: parameters)
                |> start(
                    next: { json in
                        self.pending.put(false)
                        sendCompleted(sink)
                    },
                    error: { error in
                        self.pending.put(false)
                        sendError(sink, error)
                    }
            )
            
            disposable.addDisposable {}
        }
    }
    
}
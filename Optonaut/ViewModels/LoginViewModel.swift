//
//  LoginViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class LoginViewModel {
    
    let loginEmail = MutableProperty<String>("")
    let loginEmailValid = MutableProperty<Bool>(false)
    let loginPassword = MutableProperty<String>("")
    let loginPasswordValid = MutableProperty<Bool>(false)
    let loginAllowed = MutableProperty<Bool>(false)
    let inviteEmail = MutableProperty<String>("")
    let inviteEmailValid = MutableProperty<Bool>(false)
    let inviteFormVisible = MutableProperty<Bool>(false)
    
    init() {
        loginEmail.producer
            |> start(next: { str in
                self.loginEmailValid.put(isValidEmail(str))
            })
        
        inviteEmail.producer
            |> start(next: { str in
                self.inviteEmailValid.put(isValidEmail(str))
            })
        
        loginPassword.producer
            |> start(next: { str in
                self.loginPasswordValid.put(count(str) > 4)
            })
        
        combineLatest([loginEmailValid.producer, loginPasswordValid.producer])
            |> start(next: { bools in
                self.loginAllowed.put(bools.reduce(true) { $0 && $1 })
            })
//            |> reduce { a in
//                println(a)
//                return a
//        }
    }
    
}
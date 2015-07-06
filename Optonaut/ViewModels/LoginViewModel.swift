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
    
    let loginEmailOrUserName = MutableProperty<String>("")
    let loginEmailOrUserNameValid = MutableProperty<Bool>(false)
    let loginPassword = MutableProperty<String>("")
    let loginPasswordValid = MutableProperty<Bool>(false)
    let loginAllowed = MutableProperty<Bool>(false)
    let inviteEmail = MutableProperty<String>("")
    let inviteEmailValid = MutableProperty<Bool>(false)
    let inviteFormVisible = MutableProperty<Bool>(false)
    let pending = MutableProperty<Bool>(false)
    
    init() {
        
        loginEmailOrUserName.producer
            |> start(next: { str in
                if str.rangeOfString("@") != nil {
                    self.loginEmailOrUserNameValid.put(isValidEmail(str))
                } else {
                    self.loginEmailOrUserNameValid.put(count(str) > 2)
                }
            })
        
        inviteEmail.producer
            |> start(next: { str in
                self.inviteEmailValid.put(isValidEmail(str))
            })
        
        loginPassword.producer
            |> start(next: { str in
                self.loginPasswordValid.put(count(str) > 4)
            })
        
        combineLatest([loginEmailOrUserNameValid.producer, loginPasswordValid.producer])
            |> start(next: { bools in
                self.loginAllowed.put(bools.reduce(true) { $0 && $1 })
            })
    }
    
    func login() -> SignalProducer<Void, NSError> {
        return SignalProducer { sink, disposable in
            self.pending.put(true)
            
            var parameters = [ "email": "", "user_name": "", "password": self.loginPassword.value ]
            
            if self.loginEmailOrUserName.value.rangeOfString("@") != nil {
                parameters["email"] = self.loginEmailOrUserName.value
            } else {
                parameters["user_name"] = self.loginEmailOrUserName.value
            }
            
            Api.post("users/login", authorized: false, parameters: parameters)
                |> start(
                    next: { json in
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: UserDefaultsKeys.UserIsLoggedIn.rawValue)
                        NSUserDefaults.standardUserDefaults().setObject(json["token"].stringValue, forKey: UserDefaultsKeys.UserToken.rawValue)
                        NSUserDefaults.standardUserDefaults().setInteger(json["id"].intValue, forKey: UserDefaultsKeys.UserId.rawValue)
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
    
    func requestInvite() -> SignalProducer<Void, NSError> {
        let parameters = [ "email": self.inviteEmail.value ]
        let producer = Api.post("users/request-invite", authorized: false, parameters: parameters)
            
        return producer
            |> map { _ in return }
    }
    
}
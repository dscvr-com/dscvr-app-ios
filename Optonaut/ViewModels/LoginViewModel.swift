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
    
    let emailOrUserName = MutableProperty<String>("")
    let emailOrUserNameValid = MutableProperty<Bool>(false)
    let password = MutableProperty<String>("")
    let passwordValid = MutableProperty<Bool>(false)
    let allowed = MutableProperty<Bool>(false)
    let pending = MutableProperty<Bool>(false)
    
    init() {
        
        emailOrUserName.producer
            |> start(next: { str in
                if str.rangeOfString("@") != nil {
                    self.emailOrUserNameValid.put(isValidEmail(str))
                } else {
                    self.emailOrUserNameValid.put(count(str) > 2)
                }
            })
        
        password.producer
            |> start(next: { str in
                self.passwordValid.put(count(str) > 4)
            })
        
        combineLatest([emailOrUserNameValid.producer, passwordValid.producer])
            |> start(next: { bools in
                self.allowed.put(bools.reduce(true) { $0 && $1 })
            })
    }
    
    func login() -> SignalProducer<Void, NSError> {
        return SignalProducer { sink, disposable in
            self.pending.put(true)
            
            var parameters = [ "email": "", "user_name": "", "password": self.password.value ]
            
            if self.emailOrUserName.value.rangeOfString("@") != nil {
                parameters["email"] = self.emailOrUserName.value
            } else {
                parameters["user_name"] = self.emailOrUserName.value
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
    
}
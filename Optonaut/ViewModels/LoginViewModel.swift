//
//  LoginViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper

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
                    self.emailOrUserNameValid.put(str.characters.count > 2)
                }
            })
        
        password.producer
            |> start(next: { str in
                self.passwordValid.put(str.characters.count > 4)
            })
        
        combineLatest([emailOrUserNameValid.producer, passwordValid.producer])
            |> start(next: { bools in
                self.allowed.put(bools.reduce(true) { $0 && $1 })
            })
    }
    
    func login() -> SignalProducer<Void, NSError> {
        return SignalProducer { sink, disposable in
            self.pending.put(true)
            
            var parameters = ["email": "", "user_name": "", "password": self.password.value]
            
            if self.emailOrUserName.value.rangeOfString("@") != nil {
                parameters["email"] = self.emailOrUserName.value
            } else {
                parameters["user_name"] = self.emailOrUserName.value
            }
            
            Api.post("users/login", authorized: false, parameters: parameters)
                |> start(
                    next: { json in
                        let loginData = Mapper<LoginMappable>().map(json)!
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: UserDefaultsKeys.UserIsLoggedIn.rawValue)
                        NSUserDefaults.standardUserDefaults().setObject(loginData.token, forKey: UserDefaultsKeys.UserToken.rawValue)
                        NSUserDefaults.standardUserDefaults().setInteger(loginData.id, forKey: UserDefaultsKeys.UserId.rawValue)
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

private class LoginMappable: Mappable {
    var token = ""
    var id = 0
    
    required init?(_ map: Map) {
        mapping(map)
    }
    
    func mapping(map: Map) {
        token   <- map["token"]
        id      <- map["id"]
    }
}
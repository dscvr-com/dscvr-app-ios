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
            .start(next: { str in
                if str.rangeOfString("@") != nil {
                    self.emailOrUserNameValid.value = isValidEmail(str)
                } else {
                    self.emailOrUserNameValid.value = isValidUserName(str)
                }
            })
        
        password.producer
            .start(next: { str in
                self.passwordValid.value = isValidPassword(str)
            })
        
        combineLatest([emailOrUserNameValid.producer, passwordValid.producer])
            .start(next: { bools in
                self.allowed.value = bools.reduce(true) { $0 && $1 }
            })
    }
    
    func login() -> SignalProducer<Void, NSError> {
        pending.value = true
        
        var parameters = ["email": "", "user_name": "", "password": self.password.value]
        
        if self.emailOrUserName.value.rangeOfString("@") != nil {
            parameters["email"] = self.emailOrUserName.value
        } else {
            parameters["user_name"] = self.emailOrUserName.value
        }
        
        return Api.post("persons/login", parameters: parameters)
            .on(
                next: { (loginData: LoginMappable) in
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: PersonDefaultsKeys.PersonIsLoggedIn.rawValue)
                    NSUserDefaults.standardUserDefaults().setObject(loginData.token, forKey: PersonDefaultsKeys.PersonToken.rawValue)
                    NSUserDefaults.standardUserDefaults().setInteger(loginData.id, forKey: PersonDefaultsKeys.PersonId.rawValue)
                },
                completed: {
                    self.pending.value = false
                },
                error: { error in
                    self.pending.value = false
                }
            )
            .flatMap(.Latest) { _ in SignalProducer(value: ()) }
    }
    
}

private struct LoginMappable: Mappable {
    var token = ""
    var id = 0
    
    private static func newInstance() -> Mappable {
        return LoginMappable()
    }
    
    mutating func mapping(map: Map) {
        token   <- map["token"]
        id      <- map["id"]
    }
}
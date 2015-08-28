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
import Crashlytics

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
    
    func login() -> SignalProducer<Void, ApiError> {
        pending.value = true
        
        var parameters: [String: AnyObject] = ["email": "", "user_name": "", "password": self.password.value]
        
        let usesEmail = emailOrUserName.value.rangeOfString("@") != nil
        if usesEmail {
            parameters["email"] = emailOrUserName.value
        } else {
            parameters["user_name"] = emailOrUserName.value
        }
        
        return ApiService<LoginMappable>.post("persons/login", parameters: parameters)
            .on(
                next: { loginData in
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: UserDefaultsKeys.PersonIsLoggedIn.rawValue)
                    NSUserDefaults.standardUserDefaults().setObject(loginData.token, forKey: UserDefaultsKeys.PersonToken.rawValue)
                    NSUserDefaults.standardUserDefaults().setObject(loginData.id, forKey: UserDefaultsKeys.PersonId.rawValue)
                },
                completed: {
                    self.pending.value = false
                    Answers.logLoginWithMethod(usesEmail ? "Email" : "Username", success: true, customAttributes: [:])
                },
                error: { error in
                    Answers.logLoginWithMethod(usesEmail ? "Email" : "Username", success: false, customAttributes: [:])
                    self.pending.value = false
                }
            )
            .flatMap(.Latest) { loginData in ApiService<Person>.get("persons/\(loginData.id)") }
            .on(next: { person in
                try! person.save()
            })
            .flatMap(.Latest) { _ in SignalProducer(value: ()) }
    }
    
}

private struct LoginMappable: Mappable {
    var token: String = ""
    var id: UUID = ""
    
    private static func newInstance() -> Mappable {
        return LoginMappable()
    }
    
    mutating func mapping(map: Map) {
        token   <- map["token"]
        id      <- map["id"]
    }
}
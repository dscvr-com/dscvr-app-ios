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
        
        emailOrUserName.producer.startWithNext { str in
            if str.rangeOfString("@") != nil {
                self.emailOrUserNameValid.value = isValidEmail(str)
            } else {
                self.emailOrUserNameValid.value = isValidUserName(str)
            }
        }
        
        password.producer.startWithNext { str in
            self.passwordValid.value = isValidPassword(str)
        }
        
        combineLatest([emailOrUserNameValid.producer, passwordValid.producer]).startWithNext { bools in
            self.allowed.value = bools.reduce(true) { $0 && $1 }
        }
    }
    
    func login() -> SignalProducer<Void, ApiError> {
        
        let usesEmail = emailOrUserName.value.rangeOfString("@") != nil
        let identifier = usesEmail ? LoginIdentifier.Email(emailOrUserName.value) : LoginIdentifier.UserName(emailOrUserName.value)
        
        return SessionService.login(identifier, password: password.value)
            .on(
                started: {
                    self.pending.value = true
                },
                next: { _ in
                    self.pending.value = false
                    Answers.logLoginWithMethod(usesEmail ? "Email" : "Username", success: true, customAttributes: [:])
                },
                error: { _ in
                    self.pending.value = false
                    Answers.logLoginWithMethod(usesEmail ? "Email" : "Username", success: false, customAttributes: [:])
                }
            )
            .mapError { _ in ApiError.Nil }
            .flatMap(.Latest) { _ in ApiService<Person>.get("persons/\(SessionService.sessionData!.id)") }
            .on(next: { person in
                try! person.insertOrReplace()
            })
            .flatMap(.Latest) { _ in SignalProducer(value: ()) }
    }
    
}

private struct LoginMappable: Mappable {
    var token: String = ""
    var id: UUID = ""
    
    init?(_ map: Map) {}
    
    mutating func mapping(map: Map) {
        token   <- map["token"]
        id      <- map["id"]
    }
}
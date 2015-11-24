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
    
    enum NextStep: Int {
        case Email = 1
        case Password = 2
        case Done = 3
    }
    
    enum Tab { case SignUp, LogIn }
    
    let emailOrUserName = MutableProperty<String>("")
    let emailOrUserNameValid = MutableProperty<Bool>(false)
    let password = MutableProperty<String>("")
    let passwordValid = MutableProperty<Bool>(false)
    let allowed = MutableProperty<Bool>(false)
    let pending = MutableProperty<Bool>(false)
    let facebookPending = MutableProperty<Bool>(false)
    let selectedTab = MutableProperty<Tab>(.SignUp)
    
    init() {
        
        emailOrUserNameValid <~ emailOrUserName.producer
            .map { $0.rangeOfString("@") != nil ? isValidEmail($0) : isValidUserName($0) }
            .skipRepeats()
        
        passwordValid <~ password.producer
            .map(isValidPassword)
            .skipRepeats()
        
        allowed <~ emailOrUserNameValid.producer.combineLatestWith(passwordValid.producer).map(and)
    }
    
    func submit() -> SignalProducer<Void, ApiError> {
        
        let usesEmail = emailOrUserName.value.rangeOfString("@") != nil
        let identifier = usesEmail ? LoginIdentifier.Email(emailOrUserName.value) : LoginIdentifier.UserName(emailOrUserName.value)
        
        if case .LogIn = selectedTab.value {
            return SessionService.login(identifier, password: password.value)
                .on(
                    started: {
                        self.pending.value = true
                    },
                    next: { _ in
                        self.pending.value = false
                    },
                    error: { _ in
                        self.pending.value = false
                    }
                )
                .mapError { _ in ApiError.Nil }
                .flatMap(.Latest) { _ in SignalProducer(value: ()) }
        } else {
            let parameters = [
                "email": emailOrUserName.value,
                "password": password.value,
            ]
            return ApiService<EmptyResponse>.post("persons", parameters: parameters)
                .flatMap(.Latest) { _ in SessionService.login(identifier, password: self.password.value) }
                .on(
                    started: {
                        self.pending.value = true
                    },
                    next: { _ in
                        self.pending.value = false
                    },
                    error: { _ in
                        self.pending.value = false
                    }
                )
                .mapError { _ in ApiError.Nil }
                .flatMap(.Latest) { _ in SignalProducer(value: ()) }
        }
    }
    
    func facebookSignin(userID: String, token: String) -> SignalProducer<Void, ApiError> {
        let parameters = [
            "facebook_user_id": userID,
            "facebook_token": token,
        ]
        return ApiService<LoginMappable>.post("persons/facebook/signin", parameters: parameters)
            .flatMap(.Latest) { SessionService.handleSignin($0) }
            .on(
                error: { [weak self] _ in
                    self?.facebookPending.value = false
                },
                completed: { [weak self] in
                    self?.facebookPending.value = false
                }
            )
            .flatMap(.Latest) { _ in SignalProducer(value: ()) }
    }
    
}
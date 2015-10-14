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
    
    let nextStep = MutableProperty<NextStep>(.Email)
    let emailOrUserName = MutableProperty<String>("")
    let emailOrUserNameValid = MutableProperty<Bool>(false)
    let emailOrUserNameStatus = MutableProperty<LineTextField.Status>(.Indicated)
    let password = MutableProperty<String>("")
    let passwordValid = MutableProperty<Bool>(false)
    let passwordStatus = MutableProperty<LineTextField.Status>(.Disabled)
    let allowed = MutableProperty<Bool>(false)
    let pending = MutableProperty<Bool>(false)
    
    init() {
        
        emailOrUserNameValid <~ emailOrUserName.producer
            .map { $0.rangeOfString("@") != nil ? isValidEmail($0) : isValidUserName($0) }
            .skipRepeats()
            .on(next: { valid in
                if valid {
                    self.nextStep.value = NextStep(rawValue: max(self.nextStep.value.rawValue, NextStep.Password.rawValue))!
                } else {
                    self.nextStep.value = .Email
                }
            })
        
        passwordValid <~ password.producer
            .map(isValidPassword)
            .skipRepeats()
            .on(next: { valid in
                if valid {
                    self.nextStep.value = NextStep(rawValue: max(self.nextStep.value.rawValue, NextStep.Done.rawValue))!
                } else {
                    self.nextStep.value = NextStep(rawValue: min(self.nextStep.value.rawValue, NextStep.Password.rawValue))!
                }
            })
        
        allowed <~ emailOrUserNameValid.producer.combineLatestWith(passwordValid.producer).map(and)
        
        nextStep.producer
            .skipRepeats()
            .startWithNext { state in
            switch state {
            case .Email:
                self.emailOrUserNameStatus.value = .Indicated
                self.passwordStatus.value = .Disabled
                break
            case .Password:
                self.emailOrUserNameStatus.value = .Normal
                self.passwordStatus.value = .Indicated
            case .Done:
                self.emailOrUserNameStatus.value = .Normal
                self.passwordStatus.value = .Normal
            }
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
                },
                error: { _ in
                    self.pending.value = false
                }
            )
            .mapError { _ in ApiError.Nil }
            .flatMap(.Latest) { _ in SignalProducer(value: ()) }
    }
    
}
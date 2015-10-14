//
//  OnboardingAccountViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class OnboardingAccountViewModel {
    
    enum NextStep: Int {
        case Email = 1
        case Password = 2
        case Done = 3
    }
    
    let nextStep = MutableProperty<NextStep>(.Email)
    let email = MutableProperty<String>("")
    let emailStatus = MutableProperty<LineTextField.Status>(.Disabled)
    let password = MutableProperty<String>("")
    let passwordStatus = MutableProperty<LineTextField.Status>(.Disabled)
    let loading = MutableProperty<Bool>(false)
    
    private var person = Person.newInstance()
    
    init() {
        email.producer
            .map(isValidEmail)
            .startWithNext { success in
                if success {
                    self.nextStep.value = NextStep(rawValue: max(self.nextStep.value.rawValue, NextStep.Password.rawValue))!
                } else {
                    self.nextStep.value = .Email
                }
            }
        
        password.producer
            .map(isValidPassword)
            .startWithNext { success in
                if success {
                    self.nextStep.value = NextStep(rawValue: max(self.nextStep.value.rawValue, NextStep.Done.rawValue))!
                } else {
                    self.nextStep.value = NextStep(rawValue: min(self.nextStep.value.rawValue, NextStep.Password.rawValue))!
                }
        }
        
        nextStep.producer
            .skipRepeats()
            .startWithNext { state in
            switch state {
            case .Email:
                self.emailStatus.value = .Indicated
                self.passwordStatus.value = .Disabled
                break
            case .Password:
                self.emailStatus.value = .Normal
                self.passwordStatus.value = .Indicated
            case .Done:
                self.emailStatus.value = .Normal
                self.passwordStatus.value = .Normal
            }
        }
    }
    
    func createAccount() -> SignalProducer<Void, ApiError> {
        let parameters = [
            "email": email.value,
            "password": password.value,
        ]
        return ApiService<EmptyResponse>.post("persons", parameters: parameters)
            .flatMap(.Latest) { _ in
                SessionService.login(.Email(self.email.value), password: self.password.value)
            }
            .on(
                started: {
                    self.loading.value = true
                },
                completed: {
                    self.loading.value = false
                },
                error: { _ in
                    self.loading.value = false
                }
            )
    }
    
}
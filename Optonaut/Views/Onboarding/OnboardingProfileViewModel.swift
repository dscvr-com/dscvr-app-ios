//
//  OnboardingProfileViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite


class OnboardingProfileViewModel {
    
    enum OnboardingProfileNextStep: Int {
        case Avatar = 0
        case DisplayName = 1
        case UserName = 2
        case Done = 3
    }
    
    let nextStep = MutableProperty<OnboardingProfileNextStep>(.Avatar)
    let avatarImage = MutableProperty<UIImage>(UIImage(named: "avatar-placeholder")!)
    let avatarUploaded = MutableProperty<Bool>(false)
    let displayName = MutableProperty<String>("")
    let displayNameStatus = MutableProperty<RoundedTextField.Status>(.Disabled)
    let userName = MutableProperty<String>("")
    let userNameStatus = MutableProperty<RoundedTextField.Status>(.Disabled)
    
    private var person = Person.newInstance()
    
    init() {
        avatarUploaded.producer
            .startWithNext { success in
                if success {
                    self.nextStep.value = OnboardingProfileNextStep(rawValue: max(self.nextStep.value.rawValue, OnboardingProfileNextStep.DisplayName.rawValue))!
                } else {
                    self.nextStep.value = .Avatar
                }
            }
        
        displayName.producer
            .startWithNext { val in
                if val.isEmpty {
                    self.nextStep.value = OnboardingProfileNextStep(rawValue: min(self.nextStep.value.rawValue, OnboardingProfileNextStep.DisplayName.rawValue))!
                } else {
                    self.nextStep.value = OnboardingProfileNextStep(rawValue: max(self.nextStep.value.rawValue, OnboardingProfileNextStep.UserName.rawValue))!
                }
            }
        
        var checkUserNameDisposable: Disposable?
        
        userName.producer
            .skipRepeats()
            .on(next: { userName in
                self.userNameStatus.value = .Warning("Checking username...")
                self.nextStep.value = OnboardingProfileNextStep(rawValue: min(self.nextStep.value.rawValue, OnboardingProfileNextStep.UserName.rawValue))!
            })
            .filter(isNotEmpty)
            .skipRepeats()
            .mapError { _ in ApiError.Nil }
            .throttle(0.1, onScheduler: QueueScheduler.mainQueueScheduler)
            .startWithNext { userName in
                checkUserNameDisposable?.dispose()
                // nesting needed in order to accept ApiErrors
                checkUserNameDisposable = ApiService<EmptyResponse>
                    .post("persons/me/check-user-name", parameters: ["user_name": userName])
                    .on(
                        completed: {
                            self.nextStep.value = .Done
                        },
                        error: { _ in
                            self.nextStep.value = OnboardingProfileNextStep(rawValue: min(self.nextStep.value.rawValue, OnboardingProfileNextStep.UserName.rawValue))!
                            self.userNameStatus.value = .Warning("This username is already taken. Please try another one.")
                        }
                    )
                    .start()
            }
        
        nextStep.producer
            .skipRepeats()
            .startWithNext { state in
            switch state {
            case .Avatar:
                self.displayNameStatus.value = .Disabled
                self.userNameStatus.value = .Disabled
                break
            case .DisplayName:
                self.displayNameStatus.value = .Indicated
                self.userNameStatus.value = .Disabled
            case .UserName:
                self.displayNameStatus.value = .Normal
                self.userNameStatus.value = .Indicated
            case .Done:
                self.displayNameStatus.value = .Normal
                self.userNameStatus.value = .Normal
            }
        }
    }
    
    func updateData() -> SignalProducer<EmptyResponse, ApiError> {
        if case .Done = nextStep.value {
        } else {
            return SignalProducer(error: ApiError(endpoint: "", timeout: false, status: 400, message: "Username taken", error: nil))
        }
        
        let parameters = [
            "display_name": displayName.value,
            "user_name": userName.value,
        ] as [String: AnyObject]
        
        return ApiService.put("persons/me", parameters: parameters)
            .on(completed: {
                self.person.displayName = self.displayName.value
                self.person.userName = self.userName.value
                self.saveModel()
            })
    }
    
    func updateAvatar(image: UIImage) -> SignalProducer<Person, ApiError> {
        let data = UIImageJPEGRepresentation(image, 1)
        let str = data?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        
        avatarImage.value = UIImage(data: data!)!
        
        return ApiService.post("persons/me/upload-profile-image", parameters: ["avatar_asset": str!])
            .on(
                started: {
                    self.avatarUploaded.value = true
                },
                next: { person in
                    self.person.avatarAssetId = person.avatarAssetId
                    self.avatarUploaded.value = true
                    self.saveModel()
                },
                error: { _ in
                    self.avatarUploaded.value = false
                    self.avatarImage.value = UIImage(named: "avatar-placeholder")!
                }
            )
    }
    
    private func saveModel() {
        try! person.insertOrReplace()
    }
    
}
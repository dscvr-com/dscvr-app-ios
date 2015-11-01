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
    
    enum NextStep: Int {
        case Avatar = 0
        case DisplayName = 1
        case UserName = 2
        case Done = 3
    }
    
    let nextStep = MutableProperty<NextStep>(.Avatar)
    let avatarImage = MutableProperty<UIImage>(UIImage(named: "avatar-placeholder")!)
    let avatarUploaded = MutableProperty<Bool>(false)
    let displayName = MutableProperty<String>("")
    let displayNameStatus = MutableProperty<LineTextField.Status>(.Disabled)
    let userName = MutableProperty<String>("")
    let userNameStatus = MutableProperty<LineTextField.Status>(.Disabled)
    let loading = MutableProperty<Bool>(false)
    
    private var person: Person
    
    init() {
        
        let query = PersonTable.filter(PersonTable[PersonSchema.ID] ==- SessionService.sessionData!.ID)
        person = DatabaseService.defaultConnection.pluck(query).map(Person.fromSQL)!
            
        avatarUploaded.producer
            .startWithNext { success in
                if success {
                    self.nextStep.value = NextStep(rawValue: max(self.nextStep.value.rawValue, NextStep.DisplayName.rawValue))!
                } else {
                    self.nextStep.value = .Avatar
                }
            }
        
        displayName.producer
            .startWithNext { val in
                if val.isEmpty {
                    self.nextStep.value = NextStep(rawValue: min(self.nextStep.value.rawValue, NextStep.DisplayName.rawValue))!
                } else {
                    self.nextStep.value = NextStep(rawValue: max(self.nextStep.value.rawValue, NextStep.UserName.rawValue))!
                }
            }
        
        userName.producer
            .skipRepeats()
            .on(next: { _ in
                self.nextStep.value = NextStep(rawValue: min(self.nextStep.value.rawValue, NextStep.UserName.rawValue))!
            })
            .filter(isNotEmpty)
            .on(next: { userName in
                if isValidUserName(userName) {
                    self.userNameStatus.value = .Warning("Checking username...")
                } else {
                    self.userNameStatus.value = .Warning("Invalid username")
                }
            })
            .filter(isValidUserName)
            .throttle(0.1, onScheduler: QueueScheduler.mainQueueScheduler)
            .flatMap(.Latest) { userName in
                ApiService<EmptyResponse>.post("persons/me/check-user-name", parameters: ["user_name": userName])
                    .transformToBool()
            }
            .startWithNext { success in
                if success {
                    self.nextStep.value = .Done
                } else {
                    self.nextStep.value = NextStep(rawValue: min(self.nextStep.value.rawValue, NextStep.UserName.rawValue))!
                    self.userNameStatus.value = .Warning("This username is already taken. Please try another one.")
                }
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
            .on(
                started: {
                    self.loading.value = true
                },
                completed: {
                    self.loading.value = false
                    self.person.displayName = self.displayName.value
                    self.person.userName = self.userName.value
                    self.saveModel()
                },
                error: { _ in
                    self.loading.value = false
                }
            )
    }
    
    func updateAvatar(image: UIImage) -> SignalProducer<EmptyResponse, ApiError> {
        let data = UIImageJPEGRepresentation(image, 1)
        let str = data?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        
        avatarImage.value = UIImage(data: data!)!
        
        let avatarAssetID = uuid()
        let parameters = [
            "avatar_asset": str!,
            "avatar_asset_id": avatarAssetID,
        ]
        return ApiService.post("persons/me/upload-profile-image", parameters: parameters)
            .on(
                started: {
                    self.avatarUploaded.value = true
                    self.loading.value = true
                },
                completed: { _ in
                    self.loading.value = false
                    self.person.avatarAssetID = avatarAssetID
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
        try! person.insertOrUpdate()
    }
    
}
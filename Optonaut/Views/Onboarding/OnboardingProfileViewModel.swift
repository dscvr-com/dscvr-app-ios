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
    
    let fullName = MutableProperty<String>("")
    let fullNameEditing = MutableProperty<Bool>(true)
    let fullNameEnabled = MutableProperty<Bool>(false)
    let fullNameIndicated = MutableProperty<Bool>(false)
    let userName = MutableProperty<String>("")
    let userNameEditing = MutableProperty<Bool>(true)
    let userNameEnabled = MutableProperty<Bool>(false)
    let userNameIndicated = MutableProperty<Bool>(false)
    let userNameTaken = MutableProperty<Bool>(false)
    let avatarImage = MutableProperty<UIImage>(UIImage(named: "avatar-placeholder")!)
    let avatarUploaded = MutableProperty<Bool>(false)
    let dataComplete = MutableProperty<Bool>(false)
    
    private var person = Person.newInstance()
    
    init() {
        userName.producer
            .filter(isNotEmpty)
            .skipRepeats()
            .mapError { _ in ApiError.Nil }
            .on(next: { _ in self.userNameTaken.value = false })
            .throttle(0.1, onScheduler: QueueScheduler.mainQueueScheduler)
            .startWithNext { userName in
                // nesting needed in order to accept ApiErrors
                ApiService<EmptyResponse>.post("persons/me/check-user-name", parameters: ["user_name": userName])
                    .startWithError { _ in self.userNameTaken.value = true }
            }
        
        dataComplete <~ fullName.producer.map(isNotEmpty)
            .combineLatestWith(fullNameEditing.producer.map(negate)).map(and)
            .combineLatestWith(userNameEditing.producer.map(negate)).map(and)
            .combineLatestWith(userName.producer.map(isNotEmpty)).map(and)
            .combineLatestWith(userNameTaken.producer.map(negate)).map(and)
            .combineLatestWith(avatarUploaded.producer).map(and)

        fullNameEnabled <~ avatarUploaded.producer
        
        fullNameIndicated <~ fullNameEnabled.producer
            .combineLatestWith(fullName.producer.map(isEmpty)).map(and)
        
        userNameEnabled <~ avatarUploaded.producer
            .combineLatestWith(fullName.producer.map(isNotEmpty)).map(and)
        
        userNameIndicated <~ userNameEnabled.producer
            .combineLatestWith(userName.producer.map(isEmpty)).map(and)
    }
    
    func updateData() -> SignalProducer<EmptyResponse, ApiError> {
        if userNameTaken.value {
            return SignalProducer(error: ApiError(endpoint: "", timeout: false, status: 400, message: "Username taken", error: nil))
        }
        
        let parameters = [
            "full_name": fullName.value,
            "user_name": userName.value,
        ] as [String: AnyObject]
        
        return ApiService.put("persons/me", parameters: parameters)
            .on(completed: {
                self.person.fullName = self.fullName.value
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
                }
            )
    }
    
    private func saveModel() {
        try! person.insertOrReplace()
    }
    
}
//
//  EditProfileViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite
import SwiftyUserDefaults

class EditProfileViewModel {
    
    let displayName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let userNameTaken = MutableProperty<Bool>(false)
    let text = MutableProperty<String>("")
    let email = MutableProperty<String>("")
    let avatarImageUrl = MutableProperty<String>("")
    let debugEnabled = MutableProperty<Bool>(false)
    let wantsNewsletter = MutableProperty<Bool>(false)
    
    private var person = Person.newInstance()
    
    init() {
        debugEnabled.value = Defaults[.SessionDebuggingEnabled]
        
        let query = PersonTable.filter(PersonTable[PersonSchema.ID] == Defaults[.SessionPersonID]!)
        
        if let person = DatabaseService.defaultConnection.pluck(query).map(Person.fromSQL) {
            self.person = person
            saveModel()
            updateProperties()
        }
        
        ApiService<Person>.get("persons/me").startWithNext { person in
            self.person = person
            self.saveModel()
            self.updateProperties()
        }
        
        userName.producer
            .filter(isNotEmpty)
            .mapError { _ in ApiError.Nil }
            .on(next: { _ in self.userNameTaken.value = false })
            .throttle(0.1, onScheduler: QueueScheduler.mainQueueScheduler)
            .startWithNext { userName in
                // nesting needed in order to accept ApiErrors
                ApiService<EmptyResponse>.post("persons/me/check-user-name", parameters: ["user_name": userName])
                    .startWithFailed { _ in
                        self.userNameTaken.value = self.person.userName != userName
                    }
            }
    }
    
    func updateData() -> SignalProducer<EmptyResponse, ApiError> {
        if userNameTaken.value {
            return SignalProducer(error: ApiError(endpoint: "", timeout: false, status: 400, message: "Username taken", error: nil))
        }
        
        let parameters = [
            "display_name": displayName.value,
            "user_name": userName.value,
            "text": text.value,
            "wants_newsletter": wantsNewsletter.value,
        ] as [String: AnyObject]
        
        return ApiService.put("persons/me", parameters: parameters)
            .on(completed: {
                self.updateModel()
                self.saveModel()
            })
    }
    
    func updateAvatar(image: UIImage) -> SignalProducer<EmptyResponse, ApiError> {
        let data = UIImageJPEGRepresentation(image, 1)
        let str = data?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        let avatarAssetID = uuid()
        let parameters = [
            "avatar_asset": str!,
            "avatar_asset_id": avatarAssetID,
        ]
        
        return ApiService<EmptyResponse>.post("persons/me/upload-profile-image", parameters: parameters)
            .on(completed: { [weak self] _ in
                self?.person.avatarAssetID = avatarAssetID
                self?.avatarImageUrl.value = ImageURL(avatarAssetID, width: 60, height: 60)
                self?.saveModel()
            })
    }
    
    func updatePassword(currentPassword: String, newPassword: String) -> SignalProducer<LoginMappable, ApiError> {
        return ApiService<LoginMappable>.post("persons/me/change-password", parameters: ["current": currentPassword, "new": newPassword])
            .on(next: { loginData in
                Defaults[.SessionToken] = loginData.token
                Defaults[.SessionPassword] = newPassword
            })
    }
    
    func updateEmail(email: String) -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("persons/me/change-email", parameters: ["email": email])
            .on(completed: { [weak self] in
                self?.email.value = email
                self?.person.email = email
                self?.saveModel()
            })
    }
    
    func toggleDebug() {
        debugEnabled.value = !debugEnabled.value
        Defaults[.SessionDebuggingEnabled] = debugEnabled.value
    }
    
    func toggleNewsletter() {
        wantsNewsletter.value = !wantsNewsletter.value
    }
    
    private func updateProperties() {
        email.value = person.email ?? ""
        displayName.value = person.displayName
        userName.value = person.userName
        wantsNewsletter.value = person.wantsNewsletter
        text.value = person.text
        avatarImageUrl.value = ImageURL(person.avatarAssetID, width: 60, height: 60)
    }
    
    private func updateModel() {
        person.displayName = displayName.value
        person.userName = userName.value
        person.wantsNewsletter = wantsNewsletter.value
        person.text = text.value
    }
    
    private func saveModel() {
        try! person.insertOrUpdate()
    }
    
}
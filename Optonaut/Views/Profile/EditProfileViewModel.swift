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

class EditProfileViewModel {
    
    let fullName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let userNameTaken = MutableProperty<Bool>(false)
    let text = MutableProperty<String>("")
    let email = MutableProperty<String>("")
    let avatarImage = MutableProperty<UIImage>(UIImage(named: "avatar-placeholder")!)
    let debugEnabled = MutableProperty<Bool>(false)
    let wantsNewsletter = MutableProperty<Bool>(false)
    
    private var person = Person.newInstance()
    
    init() {
        debugEnabled.value = SessionService.sessionData!.debuggingEnabled
        
        let query = PersonTable.filter(PersonTable[PersonSchema.id] == SessionService.sessionData!.id)
        
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
            .mapError { _ in ApiError.Nil }
            .on(next: { _ in self.userNameTaken.value = false })
            .throttle(0.1, onScheduler: QueueScheduler.mainQueueScheduler)
            .startWithNext { userName in
                // nesting needed in order to accept ApiErrors
                ApiService<EmptyResponse>.post("persons/me/check-user-name", parameters: ["user_name": userName])
                    .startWithError { _ in self.userNameTaken.value = true }
            }
    }
    
    func updateData() -> SignalProducer<EmptyResponse, ApiError> {
        if userNameTaken.value {
            return SignalProducer(error: ApiError(endpoint: "", timeout: false, status: 400, message: "Username taken", error: nil))
        }
        
        let parameters = [
            "full_name": fullName.value,
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
    
    func updateAvatar(image: UIImage) -> SignalProducer<Person, ApiError> {
        let data = UIImageJPEGRepresentation(image, 1)
        let str = data?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        
        avatarImage.value = UIImage(data: data!)!
        
        return ApiService.post("persons/me/upload-profile-image", parameters: ["avatar_asset": str!])
            .on(next: { person in
                self.person.avatarAssetId = person.avatarAssetId
                self.saveModel()
            })
    }
    
    func updatePassword(currentPassword: String, newPassword: String) -> SignalProducer<LoginMappable, ApiError> {
        return ApiService<LoginMappable>.post("persons/me/change-password", parameters: ["current": currentPassword, "new": newPassword])
            .on(next: { loginData in
                SessionService.sessionData?.token = loginData.token
                SessionService.sessionData?.password = newPassword
            })
    }
    
    func updateEmail(email: String) -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("persons/me/change-email", parameters: ["email": email])
    }
    
    func toggleDebug() {
        debugEnabled.value = !debugEnabled.value
        SessionService.sessionData?.debuggingEnabled = debugEnabled.value
    }
    
    func toggleNewsletter() {
        wantsNewsletter.value = !wantsNewsletter.value
    }
    
    private func updateProperties() {
        email.value = person.email
        fullName.value = person.fullName
        userName.value = person.userName
        wantsNewsletter.value = person.wantsNewsletter
        text.value = person.text
        avatarImage <~ DownloadService.downloadContents(from: "\(S3URL)/400x400/\(person.avatarAssetId).jpg", to: "\(StaticPath)/\(person.avatarAssetId).jpg").map { UIImage(data: $0)! }
    }
    
    private func updateModel() {
        person.email = email.value
        person.fullName = fullName.value
        person.userName = userName.value
        person.wantsNewsletter = wantsNewsletter.value
        person.text = text.value
    }
    
    private func saveModel() {
        try! person.insertOrReplace()
    }
    
}
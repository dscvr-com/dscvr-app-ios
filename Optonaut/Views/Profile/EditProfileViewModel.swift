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
import WebImage

class EditProfileViewModel {
    
    let fullName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let userNameTaken = MutableProperty<Bool>(false)
    let text = MutableProperty<String>("")
    let email = MutableProperty<String>("")
    let avatarImage = MutableProperty<UIImage>(UIImage(named: "avatar-placeholder")!)
    let debugEnabled = MutableProperty<Bool>(false)
    let wantsNewsletter = MutableProperty<Bool>(false)
    
    private var person = Person.newInstance() as! Person
    
    init() {
        let id = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.PersonId.rawValue) as! UUID
        debugEnabled.value = NSUserDefaults.standardUserDefaults().boolForKey(UserDefaultsKeys.DebugEnabled.rawValue)
        
        let query = PersonTable.filter(PersonTable[PersonSchema.id] == id)
        
        if let person = DatabaseManager.defaultConnection.pluck(query).map(Person.fromSQL) {
            self.person = person
            saveModel()
            updateProperties()
        }
        
        ApiService<Person>.get("persons/\(id)")
            .start(next: { person in
                self.person = person
                self.saveModel()
                self.updateProperties()
            })
        
        userName.producer
            .mapError { _ in ApiError.Nil }
            .on(next: { _ in self.userNameTaken.value = false })
            .throttle(0.1, onScheduler: QueueScheduler.mainQueueScheduler)
            .start(next: { userName in
                // nesting needed in order to accept ApiErrors
                ApiService<EmptyResponse>.post("persons/me/check-user-name", parameters: ["user_name": userName])
                    .start(error: { _ in self.userNameTaken.value = true })
            })
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
    
    func updatePassword(currentPassword: String, newPassword: String) -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("persons/me/change-password", parameters: ["current": currentPassword, "new": newPassword])
    }
    
    func updateEmail(email: String) -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("persons/me/change-email", parameters: ["email": email])
    }
    
    func toggleDebug() {
        debugEnabled.value = !debugEnabled.value
        NSUserDefaults.standardUserDefaults().setBool(debugEnabled.value, forKey: UserDefaultsKeys.DebugEnabled.rawValue)
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
        avatarImage <~ DownloadService.downloadData(from: "\(S3URL)/400x400/\(person.avatarAssetId).jpg", to: "\(StaticPath)/\(person.avatarAssetId).jpg").map { UIImage(data: $0)! }
    }
    
    private func updateModel() {
        person.email = email.value
        person.fullName = fullName.value
        person.userName = userName.value
        person.wantsNewsletter = wantsNewsletter.value
        person.text = text.value
    }
    
    private func saveModel() {
        try! person.save()
    }
    
}
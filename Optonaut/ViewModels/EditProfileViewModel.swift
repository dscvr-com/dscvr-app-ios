//
//  EditProfileViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class EditProfileViewModel {
    
    let fullName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let userNameTaken = MutableProperty<Bool>(false)
    let text = MutableProperty<String>("")
    let email = MutableProperty<String>("")
    let avatarUrl = MutableProperty<String>("")
    let debugEnabled = MutableProperty<Bool>(false)
    let wantsNewsletter = MutableProperty<Bool>(false)
    
    init() {
        let id = NSUserDefaults.standardUserDefaults().integerForKey(PersonDefaultsKeys.PersonId.rawValue)
        debugEnabled.value = NSUserDefaults.standardUserDefaults().boolForKey(PersonDefaultsKeys.DebugEnabled.rawValue)
        
//        if let person = realm.objectForPrimaryKey(Person.self, key: id) {
//            setPerson(person)
//        }
        
        Api.get("persons/\(id)")
            .start(next: setPerson)
        
        userName.producer
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil)}
            .on(next: { _ in self.userNameTaken.value = false })
            .throttle(0.1, onScheduler: QueueScheduler.mainQueueScheduler)
            .start(next: { userName in
                let parameters = ["user_name": userName]
                Api<EmptyResponse>.post("persons/me/check-user-name", parameters: parameters)
                    .start(error: { _ in self.userNameTaken.value = true })
            })
    }
    
    private func setPerson(person: Person) {
        email.value = person.email
        fullName.value = person.fullName
        userName.value = person.userName
        wantsNewsletter.value = person.wantsNewsletter
        text.value = person.text
        avatarUrl.value = "https://s3-eu-west-1.amazonaws.com/optonaut-ios-beta-dev/profile-pictures/thumb/\(person.id).jpg"
    }
    
    func updateData() -> SignalProducer<EmptyResponse, NSError> {
        let parameters = [
            "full_name": fullName.value,
            "user_name": userName.value,
            "text": text.value,
            "wants_newsletter": wantsNewsletter.value,
        ]
        
        return Api.put("persons/me", parameters: parameters as? [String : AnyObject])
    }
    
    func updateAvatar(image: UIImage) -> SignalProducer<EmptyResponse, NSError> {
        let data = UIImageJPEGRepresentation(image, 1)
        let str = data?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        
        let parameters = ["profile_picture": str!]
        return Api.post("persons/me/upload-profile-image", parameters: parameters)
    }
    
    func updatePassword(currentPassword: String, newPassword: String) {
        let parameters = ["current": currentPassword, "new": newPassword]
        
        Api<EmptyResponse>.post("persons/me/change-password", parameters: parameters)
            .start()
    }
    
    func updateEmail(email: String) {
        let parameters = ["email": email]
        
        Api<EmptyResponse>.post("persons/me/change-email", parameters: parameters)
            .start(
                completed: {
                    self.email.value = email
                }
        )
    }
    
    func toggleDebug() {
        debugEnabled.value = !debugEnabled.value
        NSUserDefaults.standardUserDefaults().setBool(debugEnabled.value, forKey: PersonDefaultsKeys.DebugEnabled.rawValue)
    }
    
    func toggleNewsletter() {
        wantsNewsletter.value = !wantsNewsletter.value
    }
    
}
//
//  EditProfileViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ObjectMapper

class EditProfileViewModel {
    
    let id = MutableProperty<Int>(0)
    let fullName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let userNameTaken = MutableProperty<Bool>(false)
    let description = MutableProperty<String>("")
    let email = MutableProperty<String>("")
    let avatarUrl = MutableProperty<String>("")
    let debugEnabled = MutableProperty<Bool>(false)
    
    init() {
        id.value = NSUserDefaults.standardUserDefaults().integerForKey(PersonDefaultsKeys.PersonId.rawValue)
        debugEnabled.value = NSUserDefaults.standardUserDefaults().boolForKey(PersonDefaultsKeys.DebugEnabled.rawValue)
        
        Api.get("persons/\(id.value)", authorized: true)
            .start(next: { json in
                let person = Mapper<Person>().map(json)!
                self.email.value = person.email
                self.fullName.value = person.fullName
                self.userName.value = person.userName
                self.description.value = person.description_
                self.avatarUrl.value = "http://beem-parts.s3.amazonaws.com/avatars/\(self.id.value % 4).jpg"
            })
        
        userName.producer
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil)}
            .filter { $0.characters.count > 2 }
            .throttle(1, onScheduler: QueueScheduler.mainQueueScheduler)
            .map { userName in ["user_name": userName] }
            .flatMap(.Latest) { parameters in Api.post("persons/check-user-name", authorized: true, parameters: parameters) }
            .start(completed: {
                self.userNameTaken.value = false
                }, error: { _ in
                self.userNameTaken.value = true
            })
    }
    
    func updateData() -> SignalProducer<JSONResponse, NSError> {
        let parameters = [
            "full_name": fullName.value,
            "user_name": userName.value,
            "description": description.value,
        ]
        
        return Api.put("persons/me", authorized: true, parameters: parameters)
    }
    
    func updateAvatar() {
        
    }
    
    func updatePassword(currentPassword: String, newPassword: String) {
        let parameters = ["current": currentPassword, "new": newPassword]
        
        Api.post("persons/me/change-password", authorized: true, parameters: parameters)
            .start(error: { error in
                print(error)
            })
    }
    
    func toggleDebug() {
        debugEnabled.value = !debugEnabled.value
        NSUserDefaults.standardUserDefaults().setBool(debugEnabled.value, forKey: PersonDefaultsKeys.DebugEnabled.rawValue)
    }
    
}
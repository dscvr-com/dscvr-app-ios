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
    }
    
    func updateData() -> SignalProducer<JSONResponse, NSError> {
        let parameters = [
            "full_name": fullName.value,
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
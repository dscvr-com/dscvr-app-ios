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
    let name = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let bio = MutableProperty<String>("")
    let email = MutableProperty<String>("")
    let avatarUrl = MutableProperty<String>("")
    let debugEnabled = MutableProperty<Bool>(false)
    
    init(id: Int) {
        self.id.value = id
        
        debugEnabled.value = NSUserDefaults.standardUserDefaults().boolForKey(UserDefaultsKeys.DebugEnabled.rawValue)
        
        Api.get("users/\(id)", authorized: true)
            .start(next: { json in
                let user = Mapper<User>().map(json)!
                self.email.value = user.email
                self.name.value = user.name
                self.userName.value = user.userName
                self.bio.value = user.bio
                self.avatarUrl.value = "http://beem-parts.s3.amazonaws.com/avatars/\(id % 4).jpg"
            })
    }
    
    func updateData() -> SignalProducer<JSONResponse, NSError> {
        let parameters = [
            "name": name.value,
            "user_name": userName.value,
            "email": email.value,
            "bio": bio.value,
        ]
        
        return Api.put("users", authorized: true, parameters: parameters)
    }
    
    func updateAvatar() {
        
    }
    
    func updatePassword(oldPassword: String, newPassword: String) {
        let parameters = ["old": oldPassword, "new": newPassword]
        
        Api.post("users/change-password", authorized: true, parameters: parameters)
            .start(error: { error in
                print(error)
            })
    }
    
    func toggleDebug() {
        debugEnabled.value = !debugEnabled.value
        NSUserDefaults.standardUserDefaults().setBool(debugEnabled.value, forKey: UserDefaultsKeys.DebugEnabled.rawValue)
    }
    
}
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
import RealmSwift

class EditProfileViewModel {
    
    let realm = try! Realm()
    
    let fullName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let userNameTaken = MutableProperty<Bool>(false)
    let description = MutableProperty<String>("")
    let email = MutableProperty<String>("")
    let avatarUrl = MutableProperty<String>("")
    let debugEnabled = MutableProperty<Bool>(false)
    let wantsNewsletter = MutableProperty<Bool>(false)
    
    init() {
        let id = NSUserDefaults.standardUserDefaults().integerForKey(PersonDefaultsKeys.PersonId.rawValue)
        debugEnabled.value = NSUserDefaults.standardUserDefaults().boolForKey(PersonDefaultsKeys.DebugEnabled.rawValue)
        
        if let person = realm.objectForPrimaryKey(Person.self, key: id) {
            setPerson(person)
        }
        
        Api.get("persons/\(id)", authorized: true)
            .map { json in Mapper<Person>().map(json)! }
            .start(next: setPerson)
        
        userName.producer
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil)}
            .on(next: { _ in self.userNameTaken.value = false })
            .throttle(0.1, onScheduler: QueueScheduler.mainQueueScheduler)
            .start(next: { userName in
                let parameters = ["user_name": userName]
                Api.post("persons/check-user-name", authorized: true, parameters: parameters)
                    .start(error: { _ in self.userNameTaken.value = true })
            })
    }
    
    private func setPerson(person: Person) {
        email.value = person.email
        fullName.value = person.fullName
        userName.value = person.userName
        description.value = person.description_
        avatarUrl.value = "http://beem-parts.s3.amazonaws.com/avatars/\(person.id % 4).jpg"
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
    
    func updateEmail(email: String) {
        let parameters = ["email": email]
        
        Api.post("persons/me/change-email", authorized: true, parameters: parameters)
            .start(completed: {
                self.email.value = email
                }, error: { error in
                    print(error)
            })
    }
    
    func toggleDebug() {
        debugEnabled.value = !debugEnabled.value
        NSUserDefaults.standardUserDefaults().setBool(debugEnabled.value, forKey: PersonDefaultsKeys.DebugEnabled.rawValue)
    }
    
}
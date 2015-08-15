//
//  OptographCellViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa
import ObjectMapper
import RealmSwift

class ProfileViewModel {
    
    let realm = try! Realm()
    
    let id = MutableProperty<Int>(0)
    let fullName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let text = MutableProperty<String>("")
    let followersCount = MutableProperty<Int>(0)
    let followedCount = MutableProperty<Int>(0)
    let isFollowed = MutableProperty<Bool>(false)
    let avatarUrl = MutableProperty<String>("")
    
    init(id: Int) {
        // TODO check if really needed here
        self.id.value = id
        
        if let person = realm.objectForPrimaryKey(Person.self, key: id) {
            setPerson(person)
        }
    
        Api.get("persons/\(id)", authorized: true)
            .start(next: { json in
                let person = Mapper<Person>().map(json)!
                self.setPerson(person)
            })
    }
    
    func toggleFollow() {
        let followedBefore = isFollowed.value
        
        isFollowed.value = !followedBefore
        
        if followedBefore {
            Api.delete("persons/\(id.value)/follow", authorized: true)
                .start(error: { _ in
                    self.isFollowed.value = followedBefore
                })
        } else {
            Api.post("persons/\(id.value)/follow", authorized: true, parameters: nil)
                .start(error: { _ in
                    self.isFollowed.value = followedBefore
                })
        }
    }
    
    private func setPerson(person: Person) {
        fullName.value = person.fullName
        userName.value = person.userName
        text.value = person.text
        followersCount.value = person.followersCount
        followedCount.value = person.followedCount
        isFollowed.value = person.isFollowed
        avatarUrl.value = "http://beem-parts.s3.amazonaws.com/avatars/\(person.id % 4).jpg"
    }
    
}

//
//  OptographCellViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa
import SQLite
import Crashlytics

class ProfileViewModel {
    
    let fullName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let text = MutableProperty<String>("")
    let followersCount = MutableProperty<Int>(0)
    let followedCount = MutableProperty<Int>(0)
    let isFollowed = MutableProperty<Bool>(false)
    let avatarUrl = MutableProperty<String>("")
    
    private var person = Person.newInstance() as! Person
    
    init(id: UUID) {
        
        Answers.logContentViewWithName("Profile \(id)",
            contentType: "Profile",
            contentId: "profile-\(id)",
            customAttributes: [:])
        
        let query = PersonTable.filter(PersonTable[PersonSchema.id] == id)
        
        if let person = DatabaseManager.defaultConnection.pluck(query).map(Person.fromSQL) {
            self.person = person
            update()
        }
    
        ApiService.get("persons/\(id)")
            .start(next: { (person: Person) in
                self.person = person
                self.update()
            })
    }
    
    func toggleFollow() {
        let followedBefore = person.isFollowed
        
        SignalProducer<Bool, ApiError>(value: followedBefore)
            .flatMap(.Latest) { followedBefore in
                followedBefore
                    ? ApiService<EmptyResponse>.delete("persons/\(self.person.id)/follow")
                    : ApiService<EmptyResponse>.post("persons/\(self.person.id)/follow", parameters: nil)
            }
            .on(started: {
                self.person.isFollowed = !followedBefore
                self.update()
            })
            .start(error: { _ in
                self.person.isFollowed = followedBefore
                self.update()
            })
    }
    
    private func update() {
        fullName.value = person.fullName
        userName.value = person.userName
        text.value = person.text
        followersCount.value = person.followersCount
        followedCount.value = person.followedCount
        isFollowed.value = person.isFollowed
        avatarUrl.value = person.avatarUrl
        
        try! person.save()
    }
    
}

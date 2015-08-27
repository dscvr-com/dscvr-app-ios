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
    
    let id = MutableProperty<UUID>("")
    let fullName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let text = MutableProperty<String>("")
    let followersCount = MutableProperty<Int>(0)
    let followedCount = MutableProperty<Int>(0)
    let isFollowed = MutableProperty<Bool>(false)
    let avatarUrl = MutableProperty<String>("")
    
    init(id: UUID) {
        
        Answers.logContentViewWithName("Profile \(id)",
            contentType: "Profile",
            contentId: "profile-\(id)",
            customAttributes: [:])
        
        // TODO check if really needed here
        self.id.value = id
        
        let query = PersonTable.filter(PersonTable[PersonSchema.id] == id)
        let person = DatabaseManager.defaultConnection.pluck(query).map { row in
            return Person(
                id: row[PersonSchema.id],
                email: row[PersonSchema.email],
                fullName: row[PersonSchema.fullName],
                userName: row[PersonSchema.userName],
                text: row[PersonSchema.text],
                followersCount: row[PersonSchema.followersCount],
                followedCount: row[PersonSchema.followedCount],
                isFollowed: row[PersonSchema.isFollowed],
                createdAt: row[PersonSchema.createdAt],
                wantsNewsletter: row[PersonSchema.wantsNewsletter]
            )
        }
        
        if let person = person {
            setPerson(person)
        }
    
        ApiService.get("persons/\(id)")
            .start(next: { (person: Person) in
                self.setPerson(person)
                
                try! DatabaseManager.defaultConnection.run(PersonTable.insert(or: .Replace, person.toSQL()))
            })
    }
    
    func toggleFollow() {
        let followedBefore = isFollowed.value
        
        isFollowed.value = !followedBefore
        
        if followedBefore {
            ApiService<EmptyResponse>.delete("persons/\(id.value)/follow")
                .start(error: { _ in
                    self.isFollowed.value = followedBefore
                })
        } else {
            ApiService<EmptyResponse>.post("persons/\(id.value)/follow", parameters: nil)
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
        avatarUrl.value = "\(StaticFilePath)/profile-images/thumb/\(person.id).jpg"
    }
    
}

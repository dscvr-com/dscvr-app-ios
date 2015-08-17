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

class ProfileViewModel {
    
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
    
        Api.get("persons/\(id)")
            .start(next: { (person: Person) in
                self.setPerson(person)
                
                try! DatabaseManager.defaultConnection.run(
                    PersonTable.insert(or: .Replace,
                        PersonSchema.id <- person.id,
                        PersonSchema.email <- person.email,
                        PersonSchema.fullName <- person.fullName,
                        PersonSchema.userName <- person.userName,
                        PersonSchema.text <- person.text,
                        PersonSchema.followersCount <- person.followersCount,
                        PersonSchema.followedCount <- person.followedCount,
                        PersonSchema.isFollowed <- person.isFollowed,
                        PersonSchema.createdAt <- person.createdAt,
                        PersonSchema.wantsNewsletter <- person.wantsNewsletter
                    )
                )
            })
    }
    
    func toggleFollow() {
        let followedBefore = isFollowed.value
        
        isFollowed.value = !followedBefore
        
        if followedBefore {
            Api<EmptyResponse>.delete("persons/\(id.value)/follow")
                .start(error: { _ in
                    self.isFollowed.value = followedBefore
                })
        } else {
            Api<EmptyResponse>.post("persons/\(id.value)/follow", parameters: nil)
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

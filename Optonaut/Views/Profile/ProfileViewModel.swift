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
    
    let displayName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let text = MutableProperty<String>("")
    let followersCount = MutableProperty<Int>(0)
    let followedCount = MutableProperty<Int>(0)
    let isFollowed = MutableProperty<Bool>(false)
    let avatarImageUrl = MutableProperty<String>("")
    
    var person = Person.newInstance()
    
    init(ID:  UUID) {
        person.ID = ID
        
        reloadModel()
    }
    
    func reloadModel() {
        let query = PersonTable.filter(PersonTable[PersonSchema.ID] == person.ID)
        
        if let person = DatabaseService.defaultConnection.pluck(query).map(Person.fromSQL) {
            self.person = person
            updateProperties()
        }
    }
    
    func toggleFollow() {
        let followedBefore = person.isFollowed
        
        SignalProducer<Bool, ApiError>(value: followedBefore)
            .flatMap(.Latest) { followedBefore in
                followedBefore
                    ? ApiService<EmptyResponse>.delete("persons/\(self.person.ID)/follow")
                    : ApiService<EmptyResponse>.post("persons/\(self.person.ID)/follow", parameters: nil)
            }
            .on(
                started: {
                    self.isFollowed.value = !followedBefore
                },
                failed: { _ in
                    self.isFollowed.value = followedBefore
                },
                completed: {
                    self.updateModel()
                    self.saveModel()
                }
            )
            .start()
    }
    
    private func updateModel() {
        person.isFollowed = isFollowed.value
    }
    
    private func updateProperties() {
        displayName.value = person.displayName
        userName.value = person.userName
        text.value = person.text
        followersCount.value = person.followersCount
        followedCount.value = person.followedCount
        isFollowed.value = person.isFollowed
        avatarImageUrl.value = ImageURL(person.avatarAssetID, width: 84, height: 84)
    }
    
    private func saveModel() {
        try! person.insertOrUpdate()
    }
    
}

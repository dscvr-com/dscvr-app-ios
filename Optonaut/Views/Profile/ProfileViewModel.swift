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
    
    private var person = Person.newInstance()
    
    init(id: UUID) {
        person.id = id
        
        reloadModel()
    }
    
    func reloadModel() {
        let query = PersonTable.filter(PersonTable[PersonSchema.id] == person.id)
        
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
                    ? ApiService<EmptyResponse>.delete("persons/\(self.person.id)/follow")
                    : ApiService<EmptyResponse>.post("persons/\(self.person.id)/follow", parameters: nil)
            }
            .on(
                started: {
                    self.isFollowed.value = !followedBefore
                },
                error: { _ in
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
        avatarImageUrl.value = "\(S3URL)/400x400/\(person.avatarAssetId).jpg"
    }
    
    private func saveModel() {
        try! person.insertOrReplace()
    }
    
}

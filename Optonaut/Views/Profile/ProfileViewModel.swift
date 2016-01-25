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
    let followingCount = MutableProperty<Int>(0)
    let postCount = MutableProperty<Int>(0)
    let isFollowed = MutableProperty<Bool>(false)
    let isEditing = MutableProperty<Bool>(false)
    let avatarImageUrl = MutableProperty<String>("")
    let isMe: Bool
//    let personID: UUID
    
//    var person = Person.newInstance()
    private var personBox: ModelBox<Person>!
    
    init(personID: UUID) {
        personBox = Models.persons[personID]!
        
//        self.personID = personID
        isMe = SessionService.personID == personID
        
        SignalProducer<Bool, ApiError>(value: SessionService.personID == personID)
            .flatMap(.Latest) { $0 ? ApiService<PersonApiModel>.get("persons/me") : ApiService<PersonApiModel>.get("persons/\(personID)") }
            .startWithNext { [weak self] apiModel in
                self?.personBox.model.mergeApiModel(apiModel)
            }
        
        personBox.producer.startWithNext { [weak self] person in
            self?.displayName.value = person.displayName
            self?.userName.value = person.userName
            self?.text.value = person.text
            self?.followersCount.value = person.followersCount
            self?.followingCount.value = person.followedCount
            self?.isFollowed.value = person.isFollowed
            self?.avatarImageUrl.value = ImageURL("persons/\(person.ID)/avatar.jpg", width: 84, height: 84)
        }
    }
    
    func saveEdit() {
        
    }
    
    func cancelEdit() {
    }
    
//    func reloadModel() {
//        let query = PersonTable.filter(PersonTable[PersonSchema.ID] == person.ID)
//        
//        if let person = DatabaseService.defaultConnection.pluck(query).map(Person.fromSQL) {
//            self.person = person
////            updateProperties()
//        }
//    }
//    
//    func toggleFollow() {
//        let followedBefore = person.isFollowed
//        
//        SignalProducer<Bool, ApiError>(value: followedBefore)
//            .flatMap(.Latest) { followedBefore in
//                followedBefore
//                    ? ApiService<EmptyResponse>.delete("persons/\(self.person.ID)/follow")
//                    : ApiService<EmptyResponse>.post("persons/\(self.person.ID)/follow", parameters: nil)
//            }
//            .on(
//                started: {
//                    self.isFollowed.value = !followedBefore
//                },
//                failed: { _ in
//                    self.isFollowed.value = followedBefore
//                },
//                completed: {
//                    self.updateModel()
////                    self.saveModel()
//                }
//            )
//            .start()
//    }
//    
//    private func updateModel() {
//        person.isFollowed = isFollowed.value
//    }
    
}

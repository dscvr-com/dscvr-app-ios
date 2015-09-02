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
    let avatarImage = MutableProperty<UIImage>(UIImage(named: "avatar-placeholder")!)
    
    private var person = Person.newInstance() as! Person
    
    init(id: UUID) {
        person.id = id
        
        Answers.logContentViewWithName("Profile \(id)",
            contentType: "Profile",
            contentId: "profile-\(id)",
            customAttributes: [:])
        
        loadModel()
    
        ApiService.get("persons/\(id)")
            .start(next: { (person: Person) in
                self.person = person
                self.saveModel()
                self.updateProperties()
            })
    }
    
    func loadModel() {
        let query = PersonTable.filter(PersonTable[PersonSchema.id] == person.id)
        
        if let person = DatabaseManager.defaultConnection.pluck(query).map(Person.fromSQL) {
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
            .on(started: {
                self.isFollowed.value = !followedBefore
            })
            .start(
                error: { _ in
                    self.isFollowed.value = followedBefore
                },
                completed: {
                    self.updateModel()
                    self.saveModel()
                }
            )
    }
    
    private func updateModel() {
        person.isFollowed = isFollowed.value
    }
    
    private func updateProperties() {
        fullName.value = person.fullName
        userName.value = person.userName
        text.value = person.text
        followersCount.value = person.followersCount
        followedCount.value = person.followedCount
        isFollowed.value = person.isFollowed
        
        avatarImage <~ DownloadService.downloadData(from: "\(S3URL)/400x400/\(person.avatarAssetId).jpg", to: "\(StaticPath)/\(person.avatarAssetId).jpg").map { UIImage(data: $0)! }
    }
    
    private func saveModel() {
        try! person.insertOrReplace()
    }
    
}

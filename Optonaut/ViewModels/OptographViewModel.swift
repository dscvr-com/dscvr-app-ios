//
//  OptographCellViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa

class OptographViewModel {
    
//    let realm = try! Realm()
    
    let id: ConstantProperty<UUID>
    let previewUrl: ConstantProperty<String>
    let avatarUrl: ConstantProperty<String>
    let fullName: ConstantProperty<String>
    let userName: ConstantProperty<String>
    let personId: ConstantProperty<UUID>
    let text: ConstantProperty<String>
    let location: ConstantProperty<String>
    
    let isStarred = MutableProperty<Bool>(false)
    let starsCount = MutableProperty<Int>(0)
    let commentCount = MutableProperty<Int>(0)
    let viewsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    
    let optograph: Optograph
    
    init(optograph: Optograph) {
        self.optograph = optograph
        
        guard let person = optograph.person else {
            fatalError("person can not be nil")
        }
        
        id = ConstantProperty(optograph.id)
        previewUrl = ConstantProperty("http://beem-parts.s3.amazonaws.com/thumbs/thumb_\(optograph.id).jpg")
        avatarUrl = ConstantProperty("https://s3-eu-west-1.amazonaws.com/optonaut-ios-beta-dev/profile-images/thumb/\(person.id).jpg")
        fullName = ConstantProperty(person.fullName)
        userName = ConstantProperty("@\(person.userName)")
        personId = ConstantProperty(person.id)
        text = ConstantProperty(optograph.text)
        location = ConstantProperty(optograph.location)
        
        isStarred.value = optograph.isStarred
        starsCount.value = optograph.starsCount
        timeSinceCreated.value = RoundedDuration(date: optograph.createdAt).longDescription()
    }
    
    func toggleLike() {
        let starredBefore = isStarred.value
        let starsCountBefore = starsCount.value
        
        starsCount.value = starsCountBefore + (starredBefore ? -1 : 1)
        isStarred.value = !starredBefore
        
        (SignalProducer(value: starredBefore) as SignalProducer<Bool, NoError>)
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil)}
            .flatMap(.Latest) { starredBefore in
                starredBefore
                    ? Api<EmptyResponse>.delete("optographs/\(self.id.value)/star")
                    : Api<EmptyResponse>.post("optographs/\(self.id.value)/star", parameters: nil)
            }
            .start(
                completed: {
//                    self.realm.write {
//                        self.optograph.isStarred = self.isStarred.value
//                        self.optograph.starsCount = self.starsCount.value
//                    }
                },
                error: { _ in
                    self.starsCount.value = starsCountBefore
                    self.isStarred.value = starredBefore
                }
            )
    }
    
}

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
        
        id = ConstantProperty(optograph.id)
        previewUrl = ConstantProperty("\(StaticFilePath)/thumbs/thumb_\(optograph.id).jpg")
        avatarUrl = ConstantProperty("\(StaticFilePath)/profile-images/thumb/\(optograph.person.id).jpg")
        fullName = ConstantProperty(optograph.person.fullName)
        userName = ConstantProperty("@\(optograph.person.userName)")
        personId = ConstantProperty(optograph.person.id)
        text = ConstantProperty(optograph.text)
        location = ConstantProperty(optograph.location.text)
        
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
                    ? ApiService<EmptyResponse>.delete("optographs/\(self.id.value)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(self.id.value)/star", parameters: nil)
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

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
    
    var optograph: Optograph
    
    init(optograph: Optograph) {
        self.optograph = optograph
        
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
        
        SignalProducer<Bool, NSError>(value: starredBefore)
            .flatMap(.Latest) { followedBefore in
                starredBefore
                    ? ApiService<EmptyResponse>.delete("optographs/\(self.optograph.id)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(self.optograph.id)/star", parameters: nil)
            }
            .on(started: {
                self.optograph.isStarred = !starredBefore
                self.optograph.starsCount += starredBefore ? -1 : 1
                self.update()
            })
            .start(error: { _ in
                self.optograph.isStarred = starredBefore
                self.optograph.starsCount = starsCountBefore
                self.update()
            })
    }
    
    private func update() {
        isStarred.value = optograph.isStarred
        starsCount.value = optograph.starsCount
        
        try! DatabaseManager.defaultConnection.run(OptographTable.insert(or: .Replace, optograph.toSQL()))
    }
    
}

//
//  OptographInfoViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ReactiveCocoa

class OptographInfoViewModel {
    
    let displayName: ConstantProperty<String>
    let avatarImageUrl: ConstantProperty<String>
    let locationText: ConstantProperty<String>
    let locationCountry: ConstantProperty<String>
    let isStarred = MutableProperty<Bool>(false)
    let starsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    
    var optograph: Optograph
    
    init(optograph: Optograph) {
        self.optograph = optograph
        
        displayName = ConstantProperty(optograph.person.displayName)
        avatarImageUrl = ConstantProperty("\(S3URL)/400x400/\(optograph.person.avatarAssetId).jpg")
        locationText = ConstantProperty(optograph.location.text)
        locationCountry = ConstantProperty(optograph.location.country)
        isStarred.value = optograph.isStarred
        starsCount.value = optograph.starsCount
        timeSinceCreated.value = optograph.createdAt.longDescription
    }
    
    func toggleLike() {
        let starredBefore = isStarred.value
        let starsCountBefore = starsCount.value
        
        SignalProducer<Bool, ApiError>(value: starredBefore)
            .flatMap(.Latest) { followedBefore in
                starredBefore
                    ? ApiService<EmptyResponse>.delete("optographs/\(self.optograph.id)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(self.optograph.id)/star", parameters: nil)
            }
            .on(
                started: {
                    self.isStarred.value = !starredBefore
                    self.starsCount.value += starredBefore ? -1 : 1
                },
                error: { _ in
                    self.isStarred.value = starredBefore
                    self.starsCount.value = starsCountBefore
                },
                completed: updateModel
            )
            .start()
    }
    
    private func updateModel() {
        optograph.isStarred = isStarred.value
        optograph.starsCount = starsCount.value
        
        try! optograph.insertOrUpdate()
    }
    
}
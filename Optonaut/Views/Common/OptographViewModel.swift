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
    
    let fullName: ConstantProperty<String>
    let userName: ConstantProperty<String>
    let personId: ConstantProperty<UUID>
    let text: ConstantProperty<String>
    let location: ConstantProperty<String>
    
    let previewImage = MutableProperty<UIImage>(UIImage(named: "optograph-placeholder")!)
    let avatarImage = MutableProperty<UIImage>(UIImage(named: "avatar-placeholder")!)
    let isStarred = MutableProperty<Bool>(false)
    let starsCount = MutableProperty<Int>(0)
    let commentCount = MutableProperty<Int>(0)
    let viewsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    
    var optograph: Optograph
    
    init(optograph: Optograph) {
        self.optograph = optograph
        
        previewImage <~ DownloadService.downloadData(from: "\(S3URL)/original/\(optograph.previewAssetId).jpg", to: "\(StaticPath)/\(optograph.previewAssetId).jpg").map { UIImage(data: $0)! }
        avatarImage <~ DownloadService.downloadData(from: "\(S3URL)/400x400/\(optograph.person.avatarAssetId).jpg", to: "\(StaticPath)/\(optograph.person.avatarAssetId).jpg").map { UIImage(data: $0)! }
        
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
        
        try! optograph.save()
    }
    
}

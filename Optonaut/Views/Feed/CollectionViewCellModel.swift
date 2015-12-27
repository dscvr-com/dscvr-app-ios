//
//  CollectionViewCellModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 25/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class CollectionViewCellModel {
    
    var optograph: Optograph
    
    let previewImageUrl: ConstantProperty<String>
    let stitchingProgress: MutableProperty<Float>
    let avatarImageUrl: ConstantProperty<String>
    let likeCount: MutableProperty<Int>
    let liked: MutableProperty<Bool>
    let textToggled = MutableProperty<Bool>(false)
    
    init(optograph: Optograph) {
        self.optograph = optograph
        
        previewImageUrl = ConstantProperty(ImageURL(optograph.previewAssetID, fullDimension: .Width))
        avatarImageUrl = ConstantProperty(ImageURL(optograph.person.avatarAssetID, width: 40, height: 40))
        likeCount = MutableProperty(optograph.starsCount)
        liked = MutableProperty(optograph.isStarred)
        
        if !optograph.isStitched && StitchingService.hasUnstitchedRecordings() {
            stitchingProgress = MutableProperty(0)
            let stitchingSignal = PipelineService.statusSignalForOptograph(optograph.ID)!
            
            stitchingSignal.observeCompleted {
                self.optograph.isStitched = true
            }
            
            stitchingProgress <~ stitchingSignal
                .map { result -> Float? in
                    if case .Stitching(let progress) = result {
                        return progress
                    } else {
                        return nil
                    }
                }
                .ignoreNil()
                .ignoreError()
        } else {
            stitchingProgress = MutableProperty(1)
        }
    }
    
    func toggleLike() {
        let starredBefore = liked.value
        let starsCountBefore = likeCount.value
        
        SignalProducer<Bool, ApiError>(value: starredBefore)
            .flatMap(.Latest) { followedBefore in
                starredBefore
                    ? ApiService<EmptyResponse>.delete("optographs/\(self.optograph.ID)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(self.optograph.ID)/star", parameters: nil)
            }
            .on(
                started: {
                    self.liked.value = !starredBefore
                    self.likeCount.value += starredBefore ? -1 : 1
                },
                failed: { _ in
                    self.liked.value = starredBefore
                    self.likeCount.value = starsCountBefore
                },
                completed: updateModel
            )
            .start()
    }
    
    
    private func updateModel() {
        optograph.isStarred = liked.value
        optograph.starsCount = likeCount.value
        
        try! optograph.insertOrUpdate()
    }
    
}
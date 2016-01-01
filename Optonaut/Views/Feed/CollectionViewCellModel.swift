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
    
    var optograph: Optograph?
    
//    let stitchingProgress: MutableProperty<Float>
    let likeCount = MutableProperty<Int>(0)
    let liked = MutableProperty<Bool>(false)
    let textToggled = MutableProperty<Bool>(false)
    let uiHidden = MutableProperty<Bool>(false)
    let isLoading = MutableProperty<Bool>(true)
    
    func bind(optograph: Optograph) {
        self.optograph = optograph
        
        likeCount.value = optograph.starsCount
        liked.value = optograph.isStarred
        textToggled.value = false
        uiHidden.value = false
        isLoading.value = true
        
//        if !optograph.isStitched && StitchingService.hasUnstitchedRecordings() {
//            stitchingProgress = MutableProperty(0)
//            let stitchingSignal = PipelineService.statusSignalForOptograph(optograph.ID)!
//            
//            stitchingSignal.observeCompleted {
//                self.optograph.isStitched = true
//            }
//            
//            stitchingProgress <~ stitchingSignal
//                .map { result -> Float? in
//                    if case .Stitching(let progress) = result {
//                        return progress
//                    } else {
//                        return nil
//                    }
//                }
//                .ignoreNil()
//                .ignoreError()
//        } else {
//            stitchingProgress = MutableProperty(1)
//        }
    }
    
    func toggleLike() {
        let starredBefore = liked.value
        let starsCountBefore = likeCount.value
        
        SignalProducer<Bool, ApiError>(value: starredBefore)
            .flatMap(.Latest) { followedBefore in
                starredBefore
                    ? ApiService<EmptyResponse>.delete("optographs/\(self.optograph!.ID)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(self.optograph!.ID)/star", parameters: nil)
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
        optograph!.isStarred = liked.value
        optograph!.starsCount = likeCount.value
        
        try! optograph!.insertOrUpdate()
    }
    
}
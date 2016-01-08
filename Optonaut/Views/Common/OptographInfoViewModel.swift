//
//  OptographInfoViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ReactiveCocoa

class OptographInfoViewModel {
    
    enum Status: Equatable {
        case Published, Publishing, Stitching, Offline, Guest
    }
    
    let displayName: ConstantProperty<String>
    let avatarImageUrl: ConstantProperty<String>
    let locationText: ConstantProperty<String>
    let locationCountry: ConstantProperty<String>
    let isStarred = MutableProperty<Bool>(false)
    let starsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    let status: MutableProperty<Status>
    
    var optograph: Optograph
    
    private var signalDisposable: Disposable?
    
    init(optograph: Optograph) {
        self.optograph = optograph
        
        displayName = ConstantProperty(optograph.person.displayName)
        avatarImageUrl = ConstantProperty(ImageURL(optograph.person.avatarAssetID, width: 40, height: 40))
        locationText = ConstantProperty(optograph.location?.text ?? "No location available")
        locationCountry = ConstantProperty(optograph.location?.country ?? "No country available")
        isStarred.value = optograph.isStarred
        starsCount.value = optograph.starsCount
        timeSinceCreated.value = optograph.createdAt.longDescription
        
        if !optograph.isStitched {
            status = MutableProperty(.Stitching)
            updateStatus()
        } else if optograph.isPublished {
            status = MutableProperty(.Published)
        } else if !SessionService.isLoggedIn {
            status = MutableProperty(.Guest)
        } else if Reachability.connectedToNetwork() {
            status = MutableProperty(.Publishing)
            updateStatus()
        } else {
            status = MutableProperty(.Offline)
        }
    }

    deinit {
        logRetain()
    }
    
    func toggleLike() {
        let starredBefore = isStarred.value
        let starsCountBefore = starsCount.value
        
        SignalProducer<Bool, ApiError>(value: starredBefore)
            .flatMap(.Latest) { followedBefore in
                starredBefore
                    ? ApiService<EmptyResponse>.delete("optographs/\(self.optograph.ID)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(self.optograph.ID)/star", parameters: nil)
            }
            .on(
                started: {
                    self.isStarred.value = !starredBefore
                    self.starsCount.value += starredBefore ? -1 : 1
                },
                failed: { _ in
                    self.isStarred.value = starredBefore
                    self.starsCount.value = starsCountBefore
                },
                completed: updateModel
            )
            .start()
    }
    
    func retryPublish() {
        PipelineService.check()
        status.value = .Publishing
        updateStatus()
    }
    
    private func updateStatus() {
//        if let signal = PipelineService.statusSignalForOptograph(optograph.ID) {
//            signalDisposable?.dispose()
//            signalDisposable = signal
//                .skipRepeats()
//                .filter([.StitchingFinished, .PublishingFinished])
//                .observeNext { [weak self] status in
//                    switch status {
//                    case .StitchingFinished: self?.status.value = Reachability.connectedToNetwork() ? .Publishing : .Offline
//                    case .PublishingFinished: self?.status.value = .Published
//                    default: break
//                    }
//                }
//        }
    }
    
    private func updateModel() {
        optograph.isStarred = isStarred.value
        optograph.starsCount = starsCount.value
        
        try! optograph.insertOrUpdate()
    }
    
}
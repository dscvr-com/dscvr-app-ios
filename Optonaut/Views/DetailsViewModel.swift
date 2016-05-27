//
//  DetailsViewModel.swift
//  Optonaut
//
//  Created by Robert John Alkuino on 05/16/16.
//  Copyright (c) 2016 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa
import SQLite
import Async

class DetailsViewModel {
    
    let isStarred = MutableProperty<Bool>(false)
    let isPublished = MutableProperty<Bool>(false)
    let starsCount = MutableProperty<Int>(0)
    let viewsCount = MutableProperty<Int>(0)
    let commentsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    let avatarImageUrl = MutableProperty<String>("")
    let textureImageUrl = MutableProperty<String>("")
    let text = MutableProperty<String>("")
    let hashtags = MutableProperty<String>("")
    let locationText = MutableProperty<String>("")
    let comments = MutableProperty<[Comment]>([])
    let viewIsActive = MutableProperty<Bool>(false)
    let isLoading = MutableProperty<Bool>(true)
    let optographReloaded = MutableProperty<Void>()
    let creator_username = MutableProperty<String>("")
    let creator_userId = MutableProperty<String>("")
    let isFollowed = MutableProperty<Bool>(false)
    var isMe = false
    
    
    var optographBox: ModelBox<Optograph>!
    var creatorDetails:ModelBox<Person>!
    
    init(optographID: UUID) {
        
        logInit()
        optographBox = Models.optographs[optographID]!
        updatePropertiesDetails()
        
        isMe = SessionService.personID == optographBox.model.personID
    }

    deinit {
        logRetain()
    }
    func toggleFollow() {
        let person = creatorDetails.model
        let followedBefore = person.isFollowed
        
        SignalProducer<Bool, ApiError>(value: followedBefore)
            .flatMap(.Latest) { followedBefore in
                followedBefore
                    ? ApiService<EmptyResponse>.delete("persons/\(person.ID)/follow")
                    : ApiService<EmptyResponse>.post("persons/\(person.ID)/follow", parameters: nil)
            }
            .on(
                started: { [weak self] in
                    self?.creatorDetails.insertOrUpdate { box in
                        box.model.isFollowed = !followedBefore
                    }
                },
                failed: { [weak self] _ in
                    self?.creatorDetails.insertOrUpdate { box in
                        box.model.isFollowed = followedBefore
                    }
                }
            )
            .start()
    }
    
    private func updatePropertiesDetails() {
        optographBox.producer.startWithNext{ [weak self] optograph in
            self?.isStarred.value = optograph.isStarred
            self?.starsCount.value = optograph.starsCount
            self?.viewsCount.value = optograph.viewsCount
            self?.commentsCount.value = optograph.commentsCount
            self?.timeSinceCreated.value = optograph.createdAt.longDescription
            self?.text.value = optograph.isPrivate ? "[private] " + optograph.text : optograph.text
            self?.hashtags.value = optograph.hashtagString
            self?.isPublished.value = optograph.isPublished
            
            if let locationID = optograph.locationID {
                let location = Models.locations[locationID]!.model
                self?.locationText.value = location.countryShort
            }
            
            self?.creatorDetails = Models.persons[optograph.personID]!
            self?.creatorDetails.producer.startWithNext{ person in
                self?.avatarImageUrl.value = "persons/\(person.ID)/\(person.avatarAssetID).jpg"
                self?.creator_username.value = person.displayName
                self?.isFollowed.value = person.isFollowed
            }
        }
    }
}

//
//  DetailsViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa
import ObjectMapper
import RealmSwift

class DetailsViewModel {
    
    let realm = try! Realm()
    
    let id = MutableProperty<Int>(0)
    let isStarred = MutableProperty<Bool>(false)
    let starsCount = MutableProperty<Int>(0)
    let commentsCount = MutableProperty<Int>(0)
    let viewsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    let detailsUrl = MutableProperty<String>("")
    let avatarUrl = MutableProperty<String>("")
    let fullName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let personId = MutableProperty<Int>(0)
    let description = MutableProperty<String>("")
    let location = MutableProperty<String>("")
    
    var optograph = Optograph()
    
    init(optographId: Int) {
        
        if let optograph = realm.objectForPrimaryKey(Optograph.self, key: optographId) {
            self.optograph = optograph
            update()
        }
        
        Api.get("optographs/\(optographId)", authorized: true)
            .map { json in Mapper<Optograph>().map(json)! }
            .start(next: { optograph in
                self.optograph = optograph
                self.update()
                
                self.realm.write {
                    self.realm.add(optograph, update: true)
                }
            })
    }
    
    private func update() {
        id.value = optograph.id
        isStarred.value = optograph.isStarred
        starsCount.value = optograph.starsCount
        commentsCount.value = optograph.commentsCount
        viewsCount.value = optograph.viewsCount
        timeSinceCreated.value = RoundedDuration(date: optograph.createdAt).longDescription()
        detailsUrl.value = "http://beem-parts.s3.amazonaws.com/thumbs/details_\(optograph.id % 3).jpg"
        avatarUrl.value = "http://beem-parts.s3.amazonaws.com/avatars/\(optograph.person!.id % 4).jpg"
        fullName.value = optograph.person!.fullName
        userName.value = "@\(optograph.person!.userName)"
        personId.value = optograph.person!.id
        description.value = optograph.description_
        location.value = optograph.location
    }
    
    func toggleLike() {
        let starredBefore = isStarred.value
        let starsCountBefore = starsCount.value
        
        starsCount.value = starsCountBefore + (starredBefore ? -1 : 1)
        isStarred.value = !starredBefore
        
        SignalProducer<Bool, NoError>(value: starredBefore)
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil)}
            .flatMap(.Latest) { starredBefore in
                starredBefore
                    ? Api.delete("optographs/\(self.id.value)/star", authorized: true)
                    : Api.post("optographs/\(self.id.value)/star", authorized: true, parameters: nil)
            }
            .start(
                completed: {
                    self.realm.write {
                        self.optograph.isStarred = self.isStarred.value
                        self.optograph.starsCount = self.starsCount.value
                    }
                },
                error: { _ in
                    self.starsCount.value = starsCountBefore
                    self.isStarred.value = starredBefore
                }
            )
    }
    
    func increaseViewsCount() {
        Api.post("optographs/\(id.value)/views", authorized: true, parameters: nil)
            .start(completed: {
                self.viewsCount.value = self.viewsCount.value + 1
                
                self.realm.write {
                    self.optograph.viewsCount = self.viewsCount.value
                }
            })
    }
    
}

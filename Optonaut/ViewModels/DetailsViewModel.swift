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
    let liked = MutableProperty<Bool>(false)
    let likeCount = MutableProperty<Int>(0)
    let commentCount = MutableProperty<Int>(0)
    let viewsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    let detailsUrl = MutableProperty<String>("")
    let avatarUrl = MutableProperty<String>("")
    let user = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let userId = MutableProperty<Int>(0)
    let text = MutableProperty<String>("")
    let location = MutableProperty<String>("")
    
    var optograph = Optograph()
    
    init(optographId: Int) {
        
        if let optograph = realm.objects(Optograph).filter("id = \(optographId)").first {
            self.optograph = optograph
            update()
        }
        
        Api.get("optographs/\(optographId)", authorized: true)
            .start(next: { json in
                self.optograph = Mapper<Optograph>().map(json)!
                self.update()
                
                self.realm.write {
                    self.realm.add(self.optograph, update: true)
                }
            })
    }
    
    private func update() {
        id.value = optograph.id
        liked.value = optograph.likedByUser
        likeCount.value = optograph.likeCount
        viewsCount.value = optograph.viewsCount
        timeSinceCreated.value = RoundedDuration(date: optograph.createdAt).longDescription()
        detailsUrl.value = "http://beem-parts.s3.amazonaws.com/thumbs/details_\(optograph.id % 3).jpg"
        avatarUrl.value = "http://beem-parts.s3.amazonaws.com/avatars/\(optograph.user!.id % 4).jpg"
        user.value = optograph.user!.name
        userName.value = "@\(optograph.user!.userName)"
        userId.value = optograph.user!.id
        text.value = optograph.text
        location.value = optograph.location
    }
    
    func toggleLike() {
        let likedBefore = liked.value
        let likeCountBefore = likeCount.value
        
        likeCount.value = likeCountBefore + (likedBefore ? -1 : 1)
        liked.value = !likedBefore
        
        SignalProducer<Bool, NoError>(value: likedBefore)
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil)}
            .flatMap(.Latest) { likedBefore in
                likedBefore
                    ? Api.delete("optographs/\(self.id.value)/like", authorized: true)
                    : Api.post("optographs/\(self.id.value)/like", authorized: true, parameters: nil)
            }
            .start(
                completed: {
                    self.realm.write {
                        self.optograph.likedByUser = self.liked.value
                        self.optograph.likeCount = self.likeCount.value
                    }
                },
                error: { _ in
                    self.likeCount.value = likeCountBefore
                    self.liked.value = likedBefore
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

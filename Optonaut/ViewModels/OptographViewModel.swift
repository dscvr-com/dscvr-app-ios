//
//  OptographCellViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa
import RealmSwift

class OptographViewModel {
    
    let realm = try! Realm()
    
    let id: ConstantProperty<Int>
    let previewUrl: ConstantProperty<String>
    let avatarUrl: ConstantProperty<String>
    let user: ConstantProperty<String>
    let userName: ConstantProperty<String>
    let userId: ConstantProperty<Int>
    let text: ConstantProperty<String>
    let location: ConstantProperty<String>
    
    let liked = MutableProperty<Bool>(false)
    let likeCount = MutableProperty<Int>(0)
    let commentCount = MutableProperty<Int>(0)
    let viewsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    
    let optograph: Optograph
    
    init(optograph: Optograph) {
        self.optograph = optograph
        
        id = ConstantProperty(optograph.id)
        previewUrl = ConstantProperty("http://beem-parts.s3.amazonaws.com/thumbs/thumb_\(optograph.id % 3).jpg")
        avatarUrl = ConstantProperty("http://beem-parts.s3.amazonaws.com/avatars/\(optograph.user!.id % 4).jpg")
        user = ConstantProperty(optograph.user!.name)
        userName = ConstantProperty("@\(optograph.user!.userName)")
        userId = ConstantProperty(optograph.user!.id)
        text = ConstantProperty(optograph.text)
        location = ConstantProperty(optograph.location)
        
        liked.value = optograph.likedByUser
        likeCount.value = optograph.likeCount
        timeSinceCreated.value = RoundedDuration(date: optograph.createdAt).longDescription()
    }
    
    func toggleLike() {
        let likedBefore = liked.value
        let likeCountBefore = likeCount.value
        
        likeCount.value = likeCountBefore + (likedBefore ? -1 : 1)
        liked.value = !likedBefore
        
        (SignalProducer(value: likedBefore) as SignalProducer<Bool, NoError>)
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
    
}

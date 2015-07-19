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
    let viewCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    
    init(optograph: Optograph) {
        id = ConstantProperty(optograph.id)
        previewUrl = ConstantProperty("http://beem-parts.s3.amazonaws.com/thumbs/thumb_\(optograph.id % 3).jpg")
        avatarUrl = ConstantProperty("http://beem-parts.s3.amazonaws.com/avatars/\(optograph.user!.id % 4).jpg")
        user = ConstantProperty(optograph.user!.name)
        userName = ConstantProperty("@\(optograph.user!.userName)")
        userId = ConstantProperty(optograph.user!.id)
        text = ConstantProperty(optograph.text)
        location = ConstantProperty(optograph.location)
        
        liked.put(optograph.likedByUser)
        likeCount.put(optograph.likeCount)
        timeSinceCreated.put(RoundedDuration(date: optograph.createdAt).longDescription())
    }
    
    func toggleLike() {
        let likedBefore = liked.value
        let likeCountBefore = likeCount.value
        
        likeCount.put(likeCountBefore + (likedBefore ? -1 : 1))
        liked.put(!likedBefore)
        
        if likedBefore {
            Api.delete("optographs/\(id.value)/like", authorized: true)
                .start(error: { _ in
                    self.likeCount.put(likeCountBefore)
                    self.liked.put(likedBefore)
                })
        } else {
            Api.post("optographs/\(id.value)/like", authorized: true, parameters: nil)
                .start(error: { _ in
                    self.likeCount.put(likeCountBefore)
                    self.liked.put(likedBefore)
                })
        }
    }
    
}

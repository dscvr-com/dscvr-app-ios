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

class DetailsViewModel {
    
    let id = MutableProperty<Int>(0)
    let liked = MutableProperty<Bool>(false)
    let likeCount = MutableProperty<Int>(0)
    let commentCount = MutableProperty<Int>(0)
    let viewCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    let detailsUrl = MutableProperty<String>("")
    let avatarUrl = MutableProperty<String>("")
    let user = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let userId = MutableProperty<Int>(0)
    let text = MutableProperty<String>("")
    let location = MutableProperty<String>("")
    
    init(optographId: Int) {
        Api.get("optographs/\(optographId)", authorized: true)
            .start(next: { json in
                let optograph = Mapper<Optograph>().map(json)!
                self.id.put(optograph.id)
                self.liked.put(optograph.likedByUser)
                self.likeCount.put(optograph.likeCount)
                self.timeSinceCreated.put(RoundedDuration(date: optograph.createdAt).longDescription())
                self.detailsUrl.put("http://beem-parts.s3.amazonaws.com/thumbs/details_\(optograph.id % 3).jpg")
                self.avatarUrl.put("http://beem-parts.s3.amazonaws.com/avatars/\(optograph.user!.id % 4).jpg")
                self.user.put(optograph.user!.name)
                self.userName.put("@\(optograph.user!.userName)")
                self.userId.put(optograph.user!.id)
                self.text.put(optograph.text)
                self.location.put(optograph.location)
            })
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

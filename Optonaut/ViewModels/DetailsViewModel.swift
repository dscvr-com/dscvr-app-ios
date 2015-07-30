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
    let viewsCount = MutableProperty<Int>(0)
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
                self.id.value = optograph.id
                self.liked.value = optograph.likedByUser
                self.likeCount.value = optograph.likeCount
                self.viewsCount.value = optograph.viewsCount
                self.timeSinceCreated.value = RoundedDuration(date: optograph.createdAt).longDescription()
                self.detailsUrl.value = "http://beem-parts.s3.amazonaws.com/thumbs/details_\(optograph.id % 3).jpg"
                self.avatarUrl.value = "http://beem-parts.s3.amazonaws.com/avatars/\(optograph.user!.id % 4).jpg"
                self.user.value = optograph.user!.name
                self.userName.value = "@\(optograph.user!.userName)"
                self.userId.value = optograph.user!.id
                self.text.value = optograph.text
                self.location.value = optograph.location
            })
    }
    
    func toggleLike() {
        let likedBefore = liked.value
        let likeCountBefore = likeCount.value
        
        likeCount.value = likeCountBefore + (likedBefore ? -1 : 1)
        liked.value = !likedBefore
        
        if likedBefore {
            Api.delete("optographs/\(id.value)/like", authorized: true)
                .start(error: { _ in
                    self.likeCount.value = likeCountBefore
                    self.liked.value = likedBefore
                })
        } else {
            Api.post("optographs/\(id.value)/like", authorized: true, parameters: nil)
                .start(error: { _ in
                    self.likeCount.value = likeCountBefore
                    self.liked.value = likedBefore
                })
        }
    }
    
    func increaseViewsCount() {
        Api.post("optographs/\(id.value)/views", authorized: true, parameters: nil).start()
        viewsCount.value = viewsCount.value + 1
    }
    
}

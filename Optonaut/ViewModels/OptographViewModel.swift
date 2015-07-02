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
    
    let id = MutableProperty<Int>(0)
    let numberOfLikes = MutableProperty<Int>(0)
    let liked = MutableProperty<Bool>(false)
    let timeSinceCreated = MutableProperty<String>("")
    let imageUrl = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let userId = MutableProperty<Int>(0)
    let text = MutableProperty<String>("")
    
    init(optograph: Optograph) {
        id.put(optograph.id)
        numberOfLikes.put(optograph.numberOfLikes)
        liked.put(optograph.likedByUser)
        timeSinceCreated.put(durationSince(optograph.createdAt))
        imageUrl.put("http://beem-parts.s3.amazonaws.com/thumbs/little_world_\(optograph.id % 10).jpg")
        userName.put("\(optograph.user!.userName)")
        userId.put(optograph.user!.id)
        text.put("@\(optograph.user!.userName) \(optograph.text)")
    }
    
    func toggleLike() {
        let likedBefore = liked.value
        let numberOfLikesBefore = numberOfLikes.value
        
        numberOfLikes.put(numberOfLikesBefore + (likedBefore ? -1 : 1))
        liked.put(!likedBefore)
        
        if likedBefore {
            Api.delete("optographs/\(id.value)/like", authorized: true)
                |> start(error: { _ in
                    self.numberOfLikes.put(numberOfLikesBefore)
                    self.liked.put(likedBefore)
                })
        } else {
            Api.post("optographs/\(id.value)/like", authorized: true, parameters: nil)
                |> start(error: { _ in
                    self.numberOfLikes.put(numberOfLikesBefore)
                    self.liked.put(likedBefore)
                })
        }
    }
    
}

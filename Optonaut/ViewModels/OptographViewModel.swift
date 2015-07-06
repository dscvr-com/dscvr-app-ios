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
    let liked = MutableProperty<Bool>(false)
    let timeSinceCreated = MutableProperty<String>("")
    let imageUrl = MutableProperty<String>("")
    let avatarUrl = MutableProperty<String>("")
    let user = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let userId = MutableProperty<Int>(0)
    let text = MutableProperty<String>("")
    let location = MutableProperty<String>("")
    
    init(optograph: Optograph) {
        id.put(optograph.id)
        liked.put(optograph.likedByUser)
        timeSinceCreated.put(RoundedDuration(date: optograph.createdAt).longDescription())
        imageUrl.put("http://beem-parts.s3.amazonaws.com/thumbs/thumb_\(optograph.id % 3).jpg")
        avatarUrl.put("http://beem-parts.s3.amazonaws.com/avatars/\(optograph.user!.id % 4).jpg")
        user.put(optograph.user!.name)
        userName.put("@\(optograph.user!.userName)")
        userId.put(optograph.user!.id)
        text.put(optograph.text)
        location.put(optograph.location)
    }
    
    func toggleLike() {
        let likedBefore = liked.value
        
        liked.put(!likedBefore)
        
        if likedBefore {
            Api.delete("optographs/\(id.value)/like", authorized: true)
                |> start(error: { _ in
                    self.liked.put(likedBefore)
                })
        } else {
            Api.post("optographs/\(id.value)/like", authorized: true, parameters: nil)
                |> start(error: { _ in
                    self.liked.put(likedBefore)
                })
        }
    }
    
}

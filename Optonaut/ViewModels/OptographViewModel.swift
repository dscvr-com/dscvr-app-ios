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
    
    init(optograph: Optograph) {
        id.put(optograph.id)
        numberOfLikes.put(optograph.numberOfLikes)
        liked.put(optograph.likedByUser)
        timeSinceCreated.put(durationSince(optograph.createdAt))
        imageUrl.put("\(optograph.id)")
    }
    
    func toggleLike() {
        let likedBefore = liked.value
        let numberOfLikesBefore = numberOfLikes.value
        
        numberOfLikes.put(numberOfLikesBefore + (likedBefore ? -1 : 1))
        liked.put(!likedBefore)
        
        if likedBefore {
            Api().delete("optographs/\(id.value)/like", authorized: true)
                |> observe(error: { _ in
                    self.numberOfLikes.put(numberOfLikesBefore)
                    self.liked.put(likedBefore)
                })
        } else {
            Api().post("optographs/\(id.value)/like", authorized: true, parameters: nil)
                |> observe(error: { _ in
                    self.numberOfLikes.put(numberOfLikesBefore)
                    self.liked.put(likedBefore)
                })
        }
    }
    
}

//
//  OptographCellViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa
import ObjectMapper

class ProfileViewModel {
    
    let id = MutableProperty<Int>(0)
    let name = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let bio = MutableProperty<String>("")
    let numberOfFollowers = MutableProperty<Int>(0)
    let numberOfFollowings = MutableProperty<Int>(0)
    let numberOfOptographs = MutableProperty<Int>(0)
    let isFollowing = MutableProperty<Bool>(false)
    let avatarUrl = MutableProperty<String>("")
    
    init(id: Int) {
        self.id.value = id
    
        Api.get("users/\(id)", authorized: true)
            .start(next: { json in
                let user = Mapper<User>().map(json)!
                self.name.value = user.name
                self.userName.value = user.userName
                self.bio.value = user.bio
                self.numberOfFollowers.value = user.numberOfFollowers
                self.numberOfFollowings.value = user.numberOfFollowings
                self.numberOfOptographs.value = user.numberOfOptographs
                self.isFollowing.value = user.isFollowing
                self.avatarUrl.value = "http://beem-parts.s3.amazonaws.com/avatars/\(id % 4).jpg"
            })
    }
    
    func toggleFollow() {
        let followedBefore = isFollowing.value
        
        isFollowing.value = !followedBefore
        
        if followedBefore {
            Api.delete("users/\(id.value)/follow", authorized: true)
                .start(error: { _ in
                    self.isFollowing.value = followedBefore
                })
        } else {
            Api.post("users/\(id.value)/follow", authorized: true, parameters: nil)
                .start(error: { _ in
                    self.isFollowing.value = followedBefore
                })
        }
    }
    
}

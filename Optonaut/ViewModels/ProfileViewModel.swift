//
//  OptographCellViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa

class ProfileViewModel {
    
    let id = MutableProperty<Int>(0)
    let userName = MutableProperty<String>("")
    let email = MutableProperty<String>("")
    let numberOfFollowers = MutableProperty<Int>(0)
    let numberOfFollowings = MutableProperty<Int>(0)
    let numberOfOptographs = MutableProperty<Int>(0)
    let isFollowing = MutableProperty<Bool>(false)
    
    init(id: Int) {
        self.id.put(id)
    
        Api.get("users/\(self.id.value)", authorized: true)
            |> start(
                next: { json in
                    let user = mapProfileUserFromJson(json)
                    self.email.put(user.email)
                    self.userName.put(user.userName)
                    self.numberOfFollowers.put(user.numberOfFollowers)
                    self.numberOfFollowings.put(user.numberOfFollowings)
                    self.numberOfOptographs.put(user.numberOfOptographs)
                    self.isFollowing.put(user.isFollowing)
                },
                error: { error in
                    println(error)
                }
        )
    }
    
    func toggleFollow() {
        let followedBefore = isFollowing.value
        
        isFollowing.put(!followedBefore)
        
        if followedBefore {
            Api.delete("users/\(id.value)/follow", authorized: true)
                |> start(error: { _ in
                    self.isFollowing.put(followedBefore)
                })
        } else {
            Api.post("users/\(id.value)/follow", authorized: true, parameters: nil)
                |> start(error: { _ in
                    self.isFollowing.put(followedBefore)
                })
        }
    }
    
}

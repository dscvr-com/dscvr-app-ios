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
import RealmSwift

class ProfileViewModel {
    
    let realm = try! Realm()
    
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
        // TODO check if really needed here
        self.id.value = id
        
        if let user = realm.objects(User).filter("id = \(id)").first {
            setUser(user)
        }
    
        Api.get("users/\(id)", authorized: true)
            .start(next: { json in
                let user = Mapper<User>().map(json)!
                self.setUser(user)
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
    
    private func setUser(user: User) {
        name.value = user.name
        userName.value = user.userName
        bio.value = user.bio
        numberOfFollowers.value = user.numberOfFollowers
        numberOfFollowings.value = user.numberOfFollowings
        numberOfOptographs.value = user.numberOfOptographs
        isFollowing.value = user.isFollowing
        avatarUrl.value = "http://beem-parts.s3.amazonaws.com/avatars/\(user.id % 4).jpg"
    }
    
}

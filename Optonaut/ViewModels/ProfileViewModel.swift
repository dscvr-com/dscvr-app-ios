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
    
    init(id: Int) {
        self.id.put(id)
    
        Api().get("users/\(self.id.value)", authorized: true)
            |> start(
                next: { json in
                    self.email.put(json["email"].stringValue)
                    self.userName.put(json["user_name"].stringValue)
                    self.numberOfFollowers.put(json["number_of_followers"].intValue)
                    self.numberOfFollowings.put(json["number_of_followings"].intValue)
                    self.numberOfOptographs.put(json["number_of_optographs"].intValue)
                },
                error: { error in
                    println(error)
                }
        )
    }
    
}

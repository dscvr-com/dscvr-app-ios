//
//  ActivityViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa
import RealmSwift

class ActivityViewModel {
    
    private let realm = try! Realm()
    
    let activityType: ConstantProperty<ActivityType>
    let creatorAvatarUrl: ConstantProperty<String>
    let creatorId: ConstantProperty<Int>
    let creatorUserName: ConstantProperty<String>
    let timeSinceCreated: ConstantProperty<String>
    let optographUrl: ConstantProperty<String?>
    let optographId: ConstantProperty<Int?>
    let readByUser: MutableProperty<Bool>
    
    private let activity: Activity
    
    init(activity: Activity) {
        self.activity = activity
        
        activityType = ConstantProperty(activity.activityType)
        creatorAvatarUrl = ConstantProperty("http://beem-parts.s3.amazonaws.com/avatars/\(activity.creator!.id % 4).jpg")
        creatorId = ConstantProperty(activity.creator!.id)
        creatorUserName = ConstantProperty(activity.creator!.userName)
        timeSinceCreated = ConstantProperty(RoundedDuration(date: activity.createdAt).shortDescription())
        optographUrl = ConstantProperty("http://beem-parts.s3.amazonaws.com/thumbs/thumb_\(activity.optograph!.id % 3).jpg")
        optographId = ConstantProperty(activity.optograph?.id)
        readByUser = MutableProperty(activity.readByUser)
    }
    
    func read() {
        Api.post("activities/\(activity.id)/read", authorized: true, parameters: nil)
            .start(completed: { _ in
                self.readByUser.value = true
                
                self.realm.write {
                    self.activity.readByUser = true
                }
            })
    }
    
}

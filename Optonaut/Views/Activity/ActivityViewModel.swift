//
//  ActivityViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa

class ActivityViewModel {
    
    let activityType: ConstantProperty<ActivityType>
    let creatorAvatarUrl = MutableProperty<UIImage>(UIImage(named: "avatar-placeholder")!)
    let creatorId: ConstantProperty<UUID>
    let creatorUserName: ConstantProperty<String>
    let timeSinceCreated: ConstantProperty<String>
    let optographUrl: ConstantProperty<String?>
    let optographId: ConstantProperty<UUID?>
    let isRead: MutableProperty<Bool>
    
    private let activity: Activity
    
    init(activity: Activity) {
        self.activity = activity
        
        activityType = ConstantProperty(activity.activityType)
//        creatorAvatarUrl = ConstantProperty(activity.creator!.avatarUrl)
        creatorId = ConstantProperty(activity.creator!.id)
        creatorUserName = ConstantProperty(activity.creator!.userName)
        timeSinceCreated = ConstantProperty(activity.createdAt.shortDescription)
        optographUrl = ConstantProperty("\(S3URL)/thumbs/thumb_\(activity.optograph!.id).jpg")
        optographId = ConstantProperty(activity.optograph?.id)
        isRead = MutableProperty(activity.isRead)
    }
    
    func read() {
        ApiService<EmptyResponse>.post("activities/\(activity.id)/read", parameters: nil)
            .start(completed: {
                self.isRead.value = true
            })
    }
    
}

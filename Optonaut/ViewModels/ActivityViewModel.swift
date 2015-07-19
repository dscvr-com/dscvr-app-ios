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
    let creatorAvatarUrl: ConstantProperty<String>
    let creatorId: ConstantProperty<Int>
    let creatorUserName: ConstantProperty<String>
    let timeSinceCreated: ConstantProperty<String>
    let optographUrl: ConstantProperty<String>
    let optograph: ConstantProperty<Optograph>
    
    init(activity: Activity) {
        activityType = ConstantProperty(activity.activityType)
        creatorAvatarUrl = ConstantProperty("http://beem-parts.s3.amazonaws.com/avatars/\(activity.creator!.id % 4).jpg")
        creatorId = ConstantProperty(activity.creator!.id)
        creatorUserName = ConstantProperty(activity.creator!.userName)
        timeSinceCreated = ConstantProperty(RoundedDuration(date: activity.createdAt).shortDescription())
        optographUrl = ConstantProperty("http://beem-parts.s3.amazonaws.com/thumbs/thumb_\(activity.optograph!.id % 3).jpg")
        optograph = ConstantProperty(activity.optograph!)
    }
    
}

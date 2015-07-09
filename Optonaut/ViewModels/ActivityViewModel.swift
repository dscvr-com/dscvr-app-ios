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
    
    let activityType = MutableProperty<ActivityType>(.Nil)
    let creatorAvatarUrl = MutableProperty<String>("")
    let creatorId = MutableProperty<Int>(0)
    let creatorUserName = MutableProperty<String>("")
    let timeSinceCreated = MutableProperty<String>("")
    let optographUrl = MutableProperty<String?>(nil)
    let optograph = MutableProperty<Optograph?>(nil)
    
    init(activity: Activity) {
        activityType.put(activity.activityType)
        creatorAvatarUrl.put("http://beem-parts.s3.amazonaws.com/avatars/\(activity.creator!.id % 4).jpg")
        creatorId.put(activity.creator!.id)
        creatorUserName.put(activity.creator!.userName)
        timeSinceCreated.put(RoundedDuration(date: activity.createdAt).shortDescription())
        
        if let optograph = activity.optograph {
            optographUrl.put("http://beem-parts.s3.amazonaws.com/thumbs/thumb_\(optograph.id % 3).jpg")
            self.optograph.put(optograph)
        }
    }
    
}

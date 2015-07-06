//
//  JsonAdapter.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/29/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import SwiftyJSON

func mapOptographFromJson(optographJson: JSON) -> Optograph {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"
    
    let user = User()
    user.id = optographJson["user"]["id"].intValue
    user.email = optographJson["user"]["email"].stringValue
    user.name = optographJson["user"]["name"].stringValue
    user.userName = optographJson["user"]["user_name"].stringValue
    
    let optograph = Optograph()
    optograph.id = optographJson["id"].intValue
    optograph.location = optographJson["location"]["description"].stringValue
    optograph.text = optographJson["text"].stringValue
    optograph.numberOfLikes = optographJson["number_of_likes"].intValue
    optograph.likedByUser = optographJson["liked_by_user"].boolValue
    optograph.createdAt = dateFormatter.dateFromString(optographJson["created_at"].stringValue)!
    optograph.user = user
    
    return optograph
}

func mapProfileUserFromJson(userJson: JSON) -> User {
    let user = User()
    user.email = userJson["email"].stringValue
    user.userName = userJson["user_name"].stringValue
    user.numberOfFollowers = userJson["number_of_followers"].intValue
    user.numberOfFollowings = userJson["number_of_followings"].intValue
    user.numberOfOptographs = userJson["number_of_optographs"].intValue
    user.isFollowing = userJson["is_following"].boolValue
    
    return user
}

func mapActivityFromJson(activityJson: JSON) -> Activity {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"
    
    let creator = User()
    creator.id = activityJson["creator"]["id"].intValue
    creator.email = activityJson["creator"]["email"].stringValue
    creator.userName = activityJson["creator"]["user_name"].stringValue
    
    let activity = Activity()
    activity.id = activityJson["id"].intValue
    activity.createdAt = dateFormatter.dateFromString(activityJson["created_at"].stringValue)!
    activity.creator = creator
    
    switch activityJson["type"].stringValue {
    case "like": activity.activityType = .Like
    case "follow": activity.activityType = .Follow
    default: activity.activityType = .Nil
    }
    
    if activityJson["optograph"].null != NSNull() {
        let optograph = Optograph()
        optograph.id = activityJson["optograph"]["id"].intValue
        optograph.text = activityJson["optograph"]["text"].stringValue
        optograph.numberOfLikes = activityJson["optograph"]["number_of_likes"].intValue
        optograph.likedByUser = activityJson["optograph"]["liked_by_user"].boolValue
        optograph.createdAt = dateFormatter.dateFromString(activityJson["optograph"]["created_at"].stringValue)!
        
        activity.optograph = optograph
    }
    
    return activity
}

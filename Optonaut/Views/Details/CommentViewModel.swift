//
//  CommentViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class CommentViewModel {
    
    let text: ConstantProperty<String>
    let avatarImageUrl: ConstantProperty<String>
    let displayName: ConstantProperty<String>
    let userName: ConstantProperty<String>
    let personID: ConstantProperty<UUID>
    let timeSinceCreated = MutableProperty<String>("")
    
    init(comment: Comment) {
        text = ConstantProperty(comment.text)
        avatarImageUrl = ConstantProperty(ImageURL(comment.person.avatarAssetID, width: 40, height: 40))
        displayName = ConstantProperty(comment.person.displayName)
        userName = ConstantProperty("@\(comment.person.userName)")
        personID = ConstantProperty(comment.person.ID)
        timeSinceCreated.value = comment.createdAt.shortDescription
    }
    
}
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
    let personId: ConstantProperty<UUID>
    let timeSinceCreated = MutableProperty<String>("")
    
    init(comment: Comment) {
        text = ConstantProperty(comment.text)
        avatarImageUrl = ConstantProperty("\(S3URL)/400x400/\(comment.person.avatarAssetId).jpg")
        displayName = ConstantProperty(comment.person.displayName)
        personId = ConstantProperty(comment.person.id)
        timeSinceCreated.value = comment.createdAt.longDescription
    }
    
}
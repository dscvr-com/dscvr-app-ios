//
//  CommentViewModel.swift
//  Iam360
//
//  Created by robert john alkuino on 6/10/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa

class CommentViewModel {
    
    let text: ConstantProperty<String>
    var avatarImageUrl = MutableProperty<String>("")
    var displayName = MutableProperty<String>("")
    var userName = MutableProperty<String>("")
    let personID: ConstantProperty<UUID>
    let timeSinceCreated = MutableProperty<String>("")
    
    init(comment: Comment) {
        
        text = ConstantProperty(comment.text)
        personID = ConstantProperty(comment.person!.ID)
        timeSinceCreated.value = comment.createdAt.shortDescription
        
        let personModel = Models.persons[comment.person!.ID]!
            
        personModel.producer
            .startWithNext { personInfo in
            print(personInfo)
                
            self.avatarImageUrl.value = ImageURL(personInfo.avatarAssetID, width: 40, height: 40)
            self.displayName.value = personInfo.displayName
            self.userName.value = "@\(personInfo.userName)"
        }
    }
}

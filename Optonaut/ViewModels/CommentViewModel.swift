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
    
    let id: ConstantProperty<Int>
    let text: ConstantProperty<String>
    
    init(comment: Comment) {
        id = ConstantProperty(comment.id)
        text = ConstantProperty(comment.text)
    }
    
}
//
//  CommentsViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class CommentsViewModel {
    
    let results = MutableProperty<[Comment]>([])
    let optographId: ConstantProperty<UUID>
    
    init(optographId: UUID) {
        self.optographId = ConstantProperty(optographId)
        
        let query = CommentTable
            .select(*)
            .join(PersonTable, on: CommentTable[CommentSchema.personId] == PersonTable[PersonSchema.id])
            .filter(CommentTable[CommentSchema.optographId] == optographId)
//            .order(CommentSchema.createdAt.asc)
        
        let comments = DatabaseManager.defaultConnection.prepare(query).map { row -> Comment in
            let person = Person.fromSQL(row)
            var comment = Comment.fromSQL(row)
            
            comment.person = person
            
            return comment
        }
        
        results.value = comments.sort { $0.createdAt < $1.createdAt }
        
        ApiService<Comment>.get("optographs/\(optographId)/comments")
            .start(next: { (var comment) in
                self.insertNewComment(comment)
                
                // TODO maybe return optograph from API?
                comment.optograph.id = optographId
                
                try! comment.person.save()
                try! comment.save()
            })
    }
    
    func insertNewComment(comment: Comment) {
        results.value.orderedInsert(comment, withOrder: .OrderedAscending)
    }
}
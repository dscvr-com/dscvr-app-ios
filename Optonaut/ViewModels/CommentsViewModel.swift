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
    
    let optographId: ConstantProperty<Int>
    let results = MutableProperty<[Comment]>([])
    
    init(optographId: Int) {
        self.optographId = ConstantProperty(optographId)
        
        let query = CommentTable.select(*).join(PersonTable, on: CommentTable[CommentSchema.personId] == PersonTable[PersonSchema.id])
        let comments = DatabaseManager.defaultConnection.prepare(query).map { row -> Comment in
            let person = Person(
                id: row[PersonSchema.id],
                email: row[PersonSchema.email],
                fullName: row[PersonSchema.fullName],
                userName: row[PersonSchema.userName],
                text: row[PersonSchema.text],
                followersCount: row[PersonSchema.followersCount],
                followedCount: row[PersonSchema.followedCount],
                isFollowed: row[PersonSchema.isFollowed],
                createdAt: row[PersonSchema.createdAt],
                wantsNewsletter: row[PersonSchema.wantsNewsletter]
            )
            
            return Comment(
                id: row[CommentSchema.id],
                text: row[CommentSchema.text],
                createdAt: row[CommentSchema.createdAt],
                person: person,
                optograph: nil
            )
        }
        
        results.value = comments
        
        Api.get("optographs/\(optographId)/comments")
            .start(next: { (comment: Comment) in
                self.results.value.append(comment)
                
                guard let person = comment.person else {
                    fatalError("person can not be nil")
                }
                
                try! DatabaseManager.defaultConnection.run(
                    CommentTable.insert(or: .Replace,
                        CommentSchema.id <- comment.id,
                        CommentSchema.text <- comment.text,
                        CommentSchema.createdAt <- comment.createdAt,
                        CommentSchema.personId <- person.id,
                        CommentSchema.optographId <- self.optographId.value
                    )
                )
                
                try! DatabaseManager.defaultConnection.run(
                    PersonTable.insert(or: .Replace,
                        PersonSchema.id <- person.id,
                        PersonSchema.email <- person.email,
                        PersonSchema.fullName <- person.fullName,
                        PersonSchema.userName <- person.userName,
                        PersonSchema.text <- person.text,
                        PersonSchema.followersCount <- person.followersCount,
                        PersonSchema.followedCount <- person.followedCount,
                        PersonSchema.isFollowed <- person.isFollowed,
                        PersonSchema.createdAt <- person.createdAt,
                        PersonSchema.wantsNewsletter <- person.wantsNewsletter
                    )
                )
                
            })
        
    }
}
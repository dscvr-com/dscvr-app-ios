//
//  DetailsViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/24/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//


import Foundation
import ReactiveCocoa
import SQLite
import Async

class DetailsViewModel {
    
    let isStarred = MutableProperty<Bool>(false)
    let isPublished = MutableProperty<Bool>(false)
    let starsCount = MutableProperty<Int>(0)
    let viewsCount = MutableProperty<Int>(0)
    let commentsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    let avatarImageUrl = MutableProperty<String>("")
    let textureImageUrl = MutableProperty<String>("")
    let text = MutableProperty<String>("")
    let hashtags = MutableProperty<String>("")
    let location = MutableProperty<String>("")
    let comments = MutableProperty<[Comment]>([])
    let viewIsActive = MutableProperty<Bool>(false)
    
    var optograph = Optograph.newInstance()
    
    init(optographId: UUID) {
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(OptographTable[OptographSchema.id] == optographId)
        
        if let optograph = DatabaseService.defaultConnection.pluck(query).map({ row -> Optograph in
            let person = Person.fromSQL(row)
            let location = Location.fromSQL(row)
            var optograph = Optograph.fromSQL(row)
            
            optograph.person = person
            optograph.location = location
            
            return optograph
        }) {
            self.optograph = optograph
            updateProperties()
        } else {
            // optograph opened via share link
            optograph.isPublished = true
        }
        
        if optograph.isPublished {
            ApiService<Optograph>.get("optographs/\(optographId)").startWithNext { optograph in
                self.optograph = optograph
                self.saveModel()
                self.updateProperties()
            }
        }
        
        let commentQuery = CommentTable
            .select(*)
            .join(PersonTable, on: CommentTable[CommentSchema.personId] == PersonTable[PersonSchema.id])
            .filter(CommentTable[CommentSchema.optographId] == optographId)
        
        DatabaseService.defaultConnection.prepare(commentQuery)
            .map { row -> Comment in
                let person = Person.fromSQL(row)
                var comment = Comment.fromSQL(row)
                
                comment.person = person
                
                return comment
            }
            .forEach(insertNewComment)
        
        ApiService<Comment>.get("optographs/\(optographId)/comments").startWithNext { (var comment) in
            self.insertNewComment(comment)
            
            comment.optograph.id = optographId
            
            try! comment.insertOrUpdate()
            try! comment.person.insertOrUpdate()
        }
    }

    deinit {
        logRetain()
    }
    
    func toggleLike() {
        let starredBefore = isStarred.value
        let starsCountBefore = starsCount.value
        
        SignalProducer<Bool, ApiError>(value: starredBefore)
            .flatMap(.Latest) { followedBefore in
                starredBefore
                    ? ApiService<EmptyResponse>.delete("optographs/\(self.optograph.id)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(self.optograph.id)/star", parameters: nil)
            }
            .on(
                started: {
                    self.isStarred.value = !starredBefore
                    self.starsCount.value += starredBefore ? -1 : 1
                },
                error: { _ in
                    self.isStarred.value = starredBefore
                    self.starsCount.value = starsCountBefore
                },
                completed: {
                    self.updateModel()
                    self.saveModel()
                }
            )
            .start()
    }
    
    func increaseViewsCount() {
        ApiService<EmptyResponse>.post("optographs/\(optograph.id)/views", parameters: nil).startWithCompleted {
            self.viewsCount.value++
            self.updateModel()
            self.saveModel()
        }
    }
    
    func publish() {
        optograph.publish()
            .startOn(QueueScheduler(queue: dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)))
            .startWithCompleted {
                self.isPublished.value = true
                self.updateModel()
                self.saveModel()
            }
    }
    
    func insertNewComment(comment: Comment) {
        comments.value.orderedInsert(comment, withOrder: .OrderedAscending)
        commentsCount.value++
    }
    
    func delete() -> SignalProducer<EmptyResponse, ApiError> {
        return optograph.delete()
    }
    
    private func updateModel() {
        optograph.isPublished = isPublished.value
        optograph.isStarred = isStarred.value
        optograph.starsCount = starsCount.value
        optograph.viewsCount = viewsCount.value
        optograph.commentsCount = commentsCount.value
    }
    
    private func saveModel() {
        try! optograph.insertOrUpdate()
        try! optograph.location.insertOrUpdate()
        try! optograph.person.insertOrUpdate()
    }
    
    private func updateProperties() {
        isStarred.value = optograph.isStarred
        starsCount.value = optograph.starsCount
        viewsCount.value = optograph.viewsCount
        commentsCount.value = optograph.commentsCount
        timeSinceCreated.value = optograph.createdAt.longDescription
        text.value = optograph.text
        hashtags.value = optograph.hashtagString
        location.value = optograph.location.text
        isPublished.value = optograph.isPublished
        avatarImageUrl.value = "\(S3URL)/400x400/\(optograph.person.avatarAssetId).jpg"
        textureImageUrl.value = optograph.leftTextureAssetURL
    }
    
}

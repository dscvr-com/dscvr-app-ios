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
    let commentsCount = MutableProperty<Int>(0)
    let viewsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    let previewImageUrl = MutableProperty<String>("")
    let avatarImageUrl = MutableProperty<String>("")
    let displayName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let personId = MutableProperty<UUID>("")
    let text = MutableProperty<String>("")
    let location = MutableProperty<String>("")
    let downloadProgress = MutableProperty<Float>(0)
    let comments = MutableProperty<[Comment]>([])
    
    var optograph: Optograph
    
    init(optographId: UUID) {
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(OptographTable[OptographSchema.id] == optographId)
        
        guard let optograph = DatabaseService.defaultConnection.pluck(query).map({ row -> Optograph in
            let person = Person.fromSQL(row)
            let location = Location.fromSQL(row)
            var optograph = Optograph.fromSQL(row)
            
            optograph.person = person
            optograph.location = location
            
            return optograph
        }) else {
            fatalError("optograph can not be nil")
        }
        
        self.optograph = optograph
        updateProperties()
        
        if !optograph.isPublished {
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
        commentsCount.value = comments.value.count
    }
    
    func delete() -> SignalProducer<EmptyResponse, ApiError> {
        return optograph.delete()
    }
    
    private func updateModel() {
        optograph.isPublished = isPublished.value
        optograph.isStarred = isStarred.value
        optograph.starsCount = starsCount.value
        optograph.viewsCount = viewsCount.value
    }
    
    private func saveModel() {
        try! optograph.insertOrUpdate()
        try! optograph.location.insertOrUpdate()
        try! optograph.person.insertOrUpdate()
    }
    
    private func updateProperties() {
        isStarred.value = optograph.isStarred
        starsCount.value = optograph.starsCount
        commentsCount.value = optograph.commentsCount
        viewsCount.value = optograph.viewsCount
        timeSinceCreated.value = optograph.createdAt.longDescription
        displayName.value = optograph.person.displayName
        userName.value = "@\(optograph.person.userName)"
        personId.value = optograph.person.id
        text.value = optograph.text
        location.value = optograph.location.text
        isPublished.value = optograph.isPublished
        previewImageUrl.value = "\(S3URL)/original/\(optograph.previewAssetId).jpg"
        avatarImageUrl.value = "\(S3URL)/400x400/\(optograph.person.avatarAssetId).jpg"

        let leftProgress = DownloadService.downloadProgress(from: "\(S3URL)/original/\(optograph.leftTextureAssetId).jpg", to: "\(StaticPath)/\(optograph.leftTextureAssetId).jpg")
        let rightProgress = DownloadService.downloadProgress(from: "\(S3URL)/original/\(optograph.rightTextureAssetId).jpg", to: "\(StaticPath)/\(optograph.rightTextureAssetId).jpg")
        downloadProgress <~ leftProgress.combineLatestWith(rightProgress).map { ($0 + $1) / 2 }
    }
    
}

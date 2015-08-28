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
    let isPublishing = MutableProperty<Bool>(false)
    let starsCount = MutableProperty<Int>(0)
    let commentsCount = MutableProperty<Int>(0)
    let viewsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    let detailsUrl = MutableProperty<String>("")
    let avatarUrl = MutableProperty<String>("")
    let fullName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let personId = MutableProperty<UUID>("")
    let text = MutableProperty<String>("")
    let location = MutableProperty<String>("")
    let downloadProgress = MutableProperty<Float>(0)
    
    var optograph: Optograph
    
    init(optographId: UUID) {
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
            .filter(OptographTable[OptographSchema.id] == optographId)
        
        guard let optograph = DatabaseManager.defaultConnection.pluck(query).map({ row -> Optograph in
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
        update()
        
        if !optograph.downloaded {
            download()
        } else {
            downloadProgress.value = 1
        }
        
        if !optograph.isPublished {
            ApiService.get("optographs/\(optographId)")
                .start(next: { (optograph: Optograph) in
                    self.optograph = optograph
                    self.update()
                })
        }
    }
    
    func toggleLike() {
        let starredBefore = isStarred.value
        let starsCountBefore = starsCount.value
        
        SignalProducer<Bool, NSError>(value: starredBefore)
            .flatMap(.Latest) { followedBefore in
                starredBefore
                    ? ApiService<EmptyResponse>.delete("optographs/\(self.optograph.id)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(self.optograph.id)/star", parameters: nil)
            }
            .on(started: {
                self.optograph.isStarred = !starredBefore
                self.optograph.starsCount += starredBefore ? -1 : 1
                self.update()
            })
            .start(error: { _ in
                self.optograph.isStarred = starredBefore
                self.optograph.starsCount = starsCountBefore
                self.update()
            })
    }
    
    func increaseViewsCount() {
        ApiService<EmptyResponse>.post("optographs/\(optograph.id)/views", parameters: nil)
            .start(completed: {
                self.optograph.viewsCount++
                self.update()
            })
    }
    
    func publish() {
        isPublishing.value = true
        
        optograph.publish()
            .startOn(QueueScheduler(queue: dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)))
            .start(completed: {
                self.optograph.isPublished = true
                self.update()
                
                self.isPublishing.value = false
            })
    }
    
    private func download() {
        var leftProgress: Float = 0
        var rightProgress: Float = 0
        for side in ["left", "right"] {
            let url = "\(StaticFilePath)/optographs/original/\(optograph.id)/\(side).jpg"
            let path = "\(optograph.path)/\(side).jpg"
            
            try! NSFileManager.defaultManager().createDirectoryAtPath(optograph.path, withIntermediateDirectories: true, attributes: nil)
            
            DownloadService.download(from: url, to: path)
                .observe(next: { progress in
                    if side == "left" {
                        leftProgress = progress
                    } else {
                        rightProgress = progress
                    }
                    self.downloadProgress.value = leftProgress / 2 + rightProgress / 2
                })
        }
    }
    
    private func update() {
        isStarred.value = optograph.isStarred
        starsCount.value = optograph.starsCount
        commentsCount.value = optograph.commentsCount
        viewsCount.value = optograph.viewsCount
        timeSinceCreated.value = RoundedDuration(date: optograph.createdAt).longDescription()
        detailsUrl.value = "\(StaticFilePath)/thumbs/details_\(optograph.id).jpg"
        avatarUrl.value = "\(StaticFilePath)/profile-images/thumb/\(optograph.person.id).jpg"
        fullName.value = optograph.person.fullName
        userName.value = "@\(optograph.person.userName)"
        personId.value = optograph.person.id
        text.value = optograph.text
        location.value = optograph.location.text
        isPublished.value = optograph.isPublished
        
        try! DatabaseManager.defaultConnection.run(PersonTable.insert(or: .Replace, optograph.person.toSQL()))
        try! DatabaseManager.defaultConnection.run(LocationTable.insert(or: .Replace, optograph.location.toSQL()))
        try! DatabaseManager.defaultConnection.run(OptographTable.insert(or: .Replace, optograph.toSQL()))
    }
    
}

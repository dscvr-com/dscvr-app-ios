//
//  FeedViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 7/23/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class FeedViewModel: NSObject {
    
    var refreshTimer: NSTimer!
    
    let results = MutableProperty<[Optograph]>([])
    let newResultsAvailable = MutableProperty<Bool>(false)
    
    let refreshNotificationSignal = NotificationSignal()
    let loadMoreNotificationSignal = NotificationSignal()
    
    override init() {
        super.init()
        
//        let meId = NSUserDefaults.standardUserDefaults().integerForKey(PersonDefaultsKeys.PersonId.rawValue)
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .join(LocationTable, on: LocationTable[LocationSchema.id] == OptographTable[OptographSchema.locationId])
//            .filter(PersonTable[PersonSchema.isFollowed] || PersonTable[PersonSchema.id] == meId)
//            .order(CommentSchema.createdAt.asc)
        let optographs = DatabaseManager.defaultConnection.prepare(query).map { row -> Optograph in
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
            
            let location = Location(
                id: row[LocationSchema.id],
                text: row[LocationSchema.text],
                createdAt: row[LocationSchema.createdAt],
                latitude: row[LocationSchema.latitude],
                longitude: row[LocationSchema.longitude]
            )
            
            return Optograph(
                id: row[OptographSchema.id],
                text: row[OptographSchema.text],
                person: person,
                createdAt: row[OptographSchema.createdAt],
                isStarred: row[OptographSchema.isStarred],
                starsCount: row[OptographSchema.starsCount],
                commentsCount: row[OptographSchema.commentsCount],
                viewsCount: row[OptographSchema.viewsCount],
                location: location,
                isPublished: row[OptographSchema.isPublished]
            )
        }
        
        results.value = optographs.sort { $0.createdAt > $1.createdAt }
        
        refreshNotificationSignal.subscribe {
            Api.get("optographs/feed")
                .on(next: { (optograph: Optograph) in
                    if let firstOptograph = self.results.value.first {
                        self.newResultsAvailable.value = optograph.id != firstOptograph.id
                    }
                })
                .start(next: processNewOptograph)
        }
        
        loadMoreNotificationSignal.subscribe {
            Api.get("optographs/feed?offset=\(results.value.count)")
                .start(next: processNewOptograph)
        }
        
        refreshNotificationSignal.notify()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refresh", userInfo: nil, repeats: true)
    }
    
    func refresh() {
        refreshNotificationSignal.notify()
    }
    
    private func processNewOptograph(optograph: Optograph) {
        results.value.orderedInsert(optograph, withOrder: .OrderedDescending)
        
        guard let person = optograph.person else {
            fatalError("person can not be nil")
        }
        
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
        
        let location = optograph.location
        
        try! DatabaseManager.defaultConnection.run(
            LocationTable.insert(or: .Replace,
                LocationSchema.id <- location.id,
                LocationSchema.text <- location.text,
                LocationSchema.createdAt <- location.createdAt,
                LocationSchema.latitude <- location.latitude,
                LocationSchema.longitude <- location.longitude
            )
        )
        
        try! DatabaseManager.defaultConnection.run(
            OptographTable.insert(or: .Replace,
                OptographSchema.id <- optograph.id,
                OptographSchema.text <- optograph.text,
                OptographSchema.personId <- person.id,
                OptographSchema.createdAt <- optograph.createdAt,
                OptographSchema.isStarred <- optograph.isStarred,
                OptographSchema.starsCount <- optograph.starsCount,
                OptographSchema.commentsCount <- optograph.commentsCount,
                OptographSchema.viewsCount <- optograph.viewsCount,
                OptographSchema.locationId <- location.id,
                OptographSchema.isPublished <- optograph.isPublished
            )
        )
    }
    
}
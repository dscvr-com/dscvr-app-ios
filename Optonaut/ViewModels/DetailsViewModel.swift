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

class DetailsViewModel {
    
    let id = MutableProperty<Int>(0)
    let isStarred = MutableProperty<Bool>(false)
    let starsCount = MutableProperty<Int>(0)
    let commentsCount = MutableProperty<Int>(0)
    let viewsCount = MutableProperty<Int>(0)
    let timeSinceCreated = MutableProperty<String>("")
    let detailsUrl = MutableProperty<String>("")
    let avatarUrl = MutableProperty<String>("")
    let fullName = MutableProperty<String>("")
    let userName = MutableProperty<String>("")
    let personId = MutableProperty<Int>(0)
    let text = MutableProperty<String>("")
    let location = MutableProperty<String>("")
    
    var optograph: Optograph!
    
    init(optographId: Int) {
        
//        if let optograph = realm.objectForPrimaryKey(Optograph.self, key: optographId) {
//            self.optograph = optograph
//            update()
//        }
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .filter(OptographTable[OptographSchema.id] == optographId)
        let optograph = DatabaseManager.defaultConnection.pluck(query).map { row -> Optograph in
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
            
            return Optograph(
                id: row[OptographSchema.id],
                text: row[OptographSchema.text],
                person: person,
                createdAt: row[OptographSchema.createdAt],
                isStarred: row[OptographSchema.isStarred],
                starsCount: row[OptographSchema.starsCount],
                commentsCount: row[OptographSchema.commentsCount],
                viewsCount: row[OptographSchema.viewsCount],
                location: row[OptographSchema.location]
            )
        }
        
        if let optograph = optograph {
            self.optograph = optograph
            update()
        }
        
        Api.get("optographs/\(optographId)")
            .start(next: { (optograph: Optograph) in
                self.optograph = optograph
                self.update()
        
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
                        OptographSchema.location <- optograph.location
                    )
                )
            })
    }
    
    private func update() {
        guard let person = optograph.person else {
            fatalError("person can not be nil")
        }
        
        id.value = optograph.id
        isStarred.value = optograph.isStarred
        starsCount.value = optograph.starsCount
        commentsCount.value = optograph.commentsCount
        viewsCount.value = optograph.viewsCount
        timeSinceCreated.value = RoundedDuration(date: optograph.createdAt).longDescription()
        detailsUrl.value = "http://beem-parts.s3.amazonaws.com/thumbs/details_\(optograph.id % 3).jpg"
        avatarUrl.value = "https://s3-eu-west-1.amazonaws.com/optonaut-ios-beta-dev/profile-pictures/thumb/\(person.id).jpg"
        fullName.value = person.fullName
        userName.value = "@\(person.userName)"
        personId.value = person.id
        text.value = optograph.text
        location.value = optograph.location
    }
    
    func toggleLike() {
        let starredBefore = isStarred.value
        let starsCountBefore = starsCount.value
        
        starsCount.value = starsCountBefore + (starredBefore ? -1 : 1)
        isStarred.value = !starredBefore
        
        SignalProducer<Bool, NoError>(value: starredBefore)
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil)}
            .flatMap(.Latest) { starredBefore in
                starredBefore
                    ? Api<EmptyResponse>.delete("optographs/\(self.id.value)/star")
                    : Api<EmptyResponse>.post("optographs/\(self.id.value)/star", parameters: nil)
            }
            .start(
                completed: {
                    //                    self.realm.write {
                    //                        self.optograph.isStarred = self.isStarred.value
                    //                        self.optograph.starsCount = self.starsCount.value
                    //                    }
                },
                error: { _ in
                    self.starsCount.value = starsCountBefore
                    self.isStarred.value = starredBefore
                }
        )
    }
    
    func increaseViewsCount() {
        Api<EmptyResponse>.post("optographs/\(id.value)/views", parameters: nil)
            .start(completed: {
                self.viewsCount.value = self.viewsCount.value + 1
                
                //                self.realm.write {
                //                    self.optograph.viewsCount = self.viewsCount.value
                //                }
            })
    }
    
}

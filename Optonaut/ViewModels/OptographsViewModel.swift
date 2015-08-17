//
//  OptographsTableViewModel.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/25/15.
//  Copyright (c) 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SQLite

class OptographsViewModel {
    
    let id: ConstantProperty<Int>
    let results = MutableProperty<[Optograph]>([])
    let resultsLoading = MutableProperty<Bool>(false)
    
    init(personId: Int) {
        id = ConstantProperty(personId)
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personId] == PersonTable[PersonSchema.id])
            .filter(PersonTable[PersonSchema.id] == personId)
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
        
        results.value = optographs.sort { $0.createdAt > $1.createdAt }
        
        resultsLoading.producer
            .mapError { _ in NSError(domain: "", code: 0, userInfo: nil) }
            .filter { $0 }
            .flatMap(.Latest) { _ in Api.get("persons/\(personId)/optographs") }
            .start(
                next: { optograph in
                    self.results.value.append(optograph)
//                    self.results.value = self.results.value.sort { $0.createdAt.compare($1.createdAt) == NSComparisonResult.OrderedDescending }
                },
                completed: {
                    self.resultsLoading.value = false
                },
                error: { _ in
                    self.resultsLoading.value = false
                }
        )
        
    }
    
}

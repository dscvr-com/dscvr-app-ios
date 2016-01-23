//
//  Person.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper
import ReactiveCocoa

struct Person: Model {
    var ID: UUID
    var createdAt: NSDate
    var updatedAt: NSDate
    var email: String?
    var displayName: String
    var userName: String
    var text: String
    var followersCount: Int
    var followedCount: Int
    var isFollowed: Bool
    var wantsNewsletter: Bool
    var avatarAssetID: UUID
    
    static let guestID: UUID = "00000000-0000-0000-0000-000000000000"
    
    static func newInstance() -> Person {
        return Person(
            ID: uuid(),
            createdAt: NSDate(),
            updatedAt: NSDate(),
            email: nil,
            displayName: "",
            userName: "",
            text: "",
            followersCount: 0,
            followedCount: 0,
            isFollowed: false,
            wantsNewsletter: false,
            avatarAssetID: ""
        )
    }
    
    func report() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("persons/\(ID)/report")
    }
}

extension Person: MergeApiModel {
    typealias AM = PersonApiModel
    
    mutating func mergeApiModel(apiModel: PersonApiModel) {
        ID = apiModel.ID
        createdAt = apiModel.createdAt
        updatedAt = apiModel.updatedAt
        email = apiModel.email
        displayName = apiModel.displayName
        userName = apiModel.userName
        text = apiModel.text
        followersCount = apiModel.followersCount
        followedCount = apiModel.followedCount
        isFollowed = apiModel.isFollowed
    }
}

func ==(lhs: Person, rhs: Person) -> Bool {
    return lhs.ID == rhs.ID
        && lhs.displayName == rhs.displayName
        && lhs.userName == rhs.userName
        && lhs.isFollowed == rhs.isFollowed
        && lhs.avatarAssetID == rhs.avatarAssetID
}

extension Person: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return PersonSchema
    }
    
    static func table() -> SQLiteTable {
        return PersonTable
    }
    
    static func fromSQL(row: SQLiteRow) -> Person {
        return Person(
            ID: row[PersonSchema.ID],
            createdAt: row[PersonSchema.createdAt],
            updatedAt: row[PersonSchema.updatedAt],
            email: row[PersonSchema.email],
            displayName: row[PersonSchema.displayName],
            userName: row[PersonSchema.userName],
            text: row[PersonSchema.text],
            followersCount: row[PersonSchema.followersCount],
            followedCount: row[PersonSchema.followedCount],
            isFollowed: row[PersonSchema.isFollowed],
            wantsNewsletter: row[PersonSchema.wantsNewsletter],
            avatarAssetID: row[PersonSchema.avatarAssetID]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        var setters = [
            PersonSchema.ID <-- ID,
            PersonSchema.createdAt <-- createdAt,
            PersonSchema.updatedAt <-- updatedAt,
            PersonSchema.displayName <-- displayName,
            PersonSchema.userName <-- userName,
            PersonSchema.text <-- text,
            PersonSchema.followersCount <-- followersCount,
            PersonSchema.followedCount <-- followedCount,
            PersonSchema.isFollowed <-- isFollowed,
            PersonSchema.wantsNewsletter <-- wantsNewsletter,
            PersonSchema.avatarAssetID <-- avatarAssetID
        ]
        
        if email != nil {
            setters.append(PersonSchema.email <-- email)
        }
        
        return setters
    }
    
}
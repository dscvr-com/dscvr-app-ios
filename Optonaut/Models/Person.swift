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
    var email: String?
    var displayName: String
    var userName: String
    var text: String
    var followersCount: Int
    var followedCount: Int
    var isFollowed: Bool
    var createdAt: NSDate
    var wantsNewsletter: Bool
    var avatarAssetID: UUID
    
    static let guestID: UUID = "00000000-0000-0000-0000-000000000000"
    
    static func newInstance() -> Person {
        return Person(
            ID: uuid(),
            email: nil,
            displayName: "",
            userName: "",
            text: "",
            followersCount: 0,
            followedCount: 0,
            isFollowed: false,
            createdAt: NSDate(),
            wantsNewsletter: false,
            avatarAssetID: uuid()
        )
    }
    
    func report() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("persons/\(ID)/report")
    }
}

extension Person: Mappable {
    
    init?(_ map: Map){
        self = Person.newInstance()
    }
    
    mutating func mapping(map: Map) {
        ID                  <- map["id"]
        email               <- map["email"]
        displayName         <- map["display_name"]
        userName            <- map["user_name"]
        text                <- map["text"]
        followersCount      <- map["followers_count"]
        followedCount       <- map["followed_count"]
        isFollowed          <- map["is_followed"]
        createdAt           <- (map["created_at"], NSDateTransform())
        wantsNewsletter     <- map["wants_newsletter"]
        avatarAssetID       <- map["avatar_asset_id"]
    }
    
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
            email: row[PersonSchema.email],
            displayName: row[PersonSchema.displayName],
            userName: row[PersonSchema.userName],
            text: row[PersonSchema.text],
            followersCount: row[PersonSchema.followersCount],
            followedCount: row[PersonSchema.followedCount],
            isFollowed: row[PersonSchema.isFollowed],
            createdAt: row[PersonSchema.createdAt],
            wantsNewsletter: row[PersonSchema.wantsNewsletter],
            avatarAssetID: row[PersonSchema.avatarAssetID]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        var setters = [
            PersonSchema.ID <-- ID,
            PersonSchema.displayName <-- displayName,
            PersonSchema.userName <-- userName,
            PersonSchema.text <-- text,
            PersonSchema.followersCount <-- followersCount,
            PersonSchema.followedCount <-- followedCount,
            PersonSchema.isFollowed <-- isFollowed,
            PersonSchema.createdAt <-- createdAt,
            PersonSchema.wantsNewsletter <-- wantsNewsletter,
            PersonSchema.avatarAssetID <-- avatarAssetID
        ]
        
        if email != nil {
            setters.append(PersonSchema.email <-- email)
        }
        
        return setters
    }
    
}
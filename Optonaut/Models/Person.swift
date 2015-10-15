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
    var id: UUID
    var email: String?
    var displayName: String
    var userName: String
    var text: String
    var followersCount: Int
    var followedCount: Int
    var isFollowed: Bool
    var createdAt: NSDate
    var wantsNewsletter: Bool
    var avatarAssetId: UUID
    
    static func newInstance() -> Person {
        return Person(
            id: uuid(),
            email: nil,
            displayName: "",
            userName: "",
            text: "",
            followersCount: 0,
            followedCount: 0,
            isFollowed: false,
            createdAt: NSDate(),
            wantsNewsletter: false,
            avatarAssetId: uuid()
        )
    }
    
    func report() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("persons/\(id)/report")
    }
}

extension Person: Mappable {
    
    init?(_ map: Map){
        self = Person.newInstance()
    }
    
    mutating func mapping(map: Map) {
        id                  <- map["id"]
        email               <- map["email"]
        displayName         <- map["display_name"]
        userName            <- map["user_name"]
        text                <- map["text"]
        followersCount      <- map["followers_count"]
        followedCount       <- map["followed_count"]
        isFollowed          <- map["is_followed"]
        createdAt           <- (map["created_at"], NSDateTransform())
        wantsNewsletter     <- map["wants_newsletter"]
        avatarAssetId       <- map["avatar_asset_id"]
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
            id: row[PersonSchema.id],
            email: row[PersonSchema.email],
            displayName: row[PersonSchema.displayName],
            userName: row[PersonSchema.userName],
            text: row[PersonSchema.text],
            followersCount: row[PersonSchema.followersCount],
            followedCount: row[PersonSchema.followedCount],
            isFollowed: row[PersonSchema.isFollowed],
            createdAt: row[PersonSchema.createdAt],
            wantsNewsletter: row[PersonSchema.wantsNewsletter],
            avatarAssetId: row[PersonSchema.avatarAssetId]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        var setters = [
            PersonSchema.id <-- id,
            PersonSchema.displayName <-- displayName,
            PersonSchema.userName <-- userName,
            PersonSchema.text <-- text,
            PersonSchema.followersCount <-- followersCount,
            PersonSchema.followedCount <-- followedCount,
            PersonSchema.isFollowed <-- isFollowed,
            PersonSchema.createdAt <-- createdAt,
            PersonSchema.wantsNewsletter <-- wantsNewsletter,
            PersonSchema.avatarAssetId <-- avatarAssetId
        ]
        
        if email != nil {
            setters.append(PersonSchema.email <-- email)
        }
        
        return setters
    }
    
}
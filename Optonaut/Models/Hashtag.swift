//
//  Hashtag.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct Hashtag: Model {
    var ID: UUID
    var createdAt: NSDate
    var name: String
    var previewAssetID: UUID
    var isFollowed: Bool
    
    static func newInstance() -> Hashtag {
        return Hashtag(
            ID: uuid(),
            createdAt: NSDate(),
            name: "",
            previewAssetID: "",
            isFollowed: false
        )
    }
    
}

extension Hashtag: Mappable {
    
    init?(_ map: Map){
        self = Hashtag.newInstance()
    }
    
    mutating func mapping(map: Map) {
        ID                  <- map["id"]
        name                <- map["name"]
        previewAssetID      <- map["preview_asset_id"]
        isFollowed          <- map["is_followed"]
    }
    
}

extension Hashtag: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return HashtagSchema
    }
    
    static func table() -> SQLiteTable {
        return HashtagTable
    }
    
    static func fromSQL(row: SQLiteRow) -> Hashtag {
        return Hashtag(
            ID: row[HashtagSchema.ID],
            createdAt: NSDate(),
            name: row[HashtagSchema.name],
            previewAssetID: row[HashtagSchema.previewAssetID],
            isFollowed: row[HashtagSchema.isFollowed]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            HashtagSchema.ID <-- ID,
            HashtagSchema.name <-- name,
            HashtagSchema.previewAssetID <-- previewAssetID,
            HashtagSchema.isFollowed <-- isFollowed,
        ]
    }
    
}
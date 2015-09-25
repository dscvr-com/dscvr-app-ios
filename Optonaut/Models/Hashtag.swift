//
//  Hashtag.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ObjectMapper

struct Hashtag {
    var id: UUID
    var name: String
    var previewAssetId: UUID
    var isFollowed: Bool
    
    static func newInstance() -> Hashtag {
        return Hashtag(
            id: uuid(),
            name: "",
            previewAssetId: uuid(),
            isFollowed: false
        )
    }
    
}

extension Hashtag: Mappable {
    
    init?(_ map: Map){
        self = Hashtag.newInstance()
    }
    
    mutating func mapping(map: Map) {
        id                  <- map["id"]
        name                <- map["name"]
        previewAssetId      <- map["preview_asset_id"]
        isFollowed          <- map["is_followed"]
    }
    
}

extension Hashtag: SQLiteModel {
    
    static func fromSQL(row: SQLiteRow) -> Hashtag {
        return Hashtag(
            id: row[HashtagSchema.id],
            name: row[HashtagSchema.name],
            previewAssetId: row[HashtagSchema.previewAssetId],
            isFollowed: row[HashtagSchema.isFollowed]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            HashtagSchema.id <-- id,
            HashtagSchema.name <-- name,
            HashtagSchema.previewAssetId <-- previewAssetId,
            HashtagSchema.isFollowed <-- isFollowed,
        ]
    }
    
    func insertOrReplace() throws {
        try DatabaseService.defaultConnection.run(HashtagTable.insert(or: .Replace, toSQL()))
    }
    
}
//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper
import ReactiveCocoa

enum OptographAsset {
    case PreviewImage(NSData)
    case LeftImage(NSData)
    case RightImage(NSData)
}

typealias HashtagStrings = Array<String>

struct Optograph: Model {
    
    var id: UUID
    var text: String
    var person: Person
    var createdAt: NSDate
    var deleted: Bool
    var isStarred: Bool
    var starsCount: Int
    var commentsCount: Int
    var viewsCount: Int
    var location: Location
    var isStitched: Bool
    var isPublished: Bool
    var previewAssetId: UUID
    var leftTextureAssetId: UUID
    var rightTextureAssetId: UUID
    var isStaffPick: Bool
    var hashtagString: String
    
    static func newInstance() -> Optograph {
        return Optograph(
            id: uuid(),
            text: "",
            person: Person.newInstance(),
            createdAt: NSDate(),
            deleted: false,
            isStarred: false,
            starsCount: 0,
            commentsCount: 0,
            viewsCount: 0,
            location: Location.newInstance(),
            isStitched: false,
            isPublished: false,
            previewAssetId: uuid(),
            leftTextureAssetId: uuid(),
            rightTextureAssetId: uuid(),
            isStaffPick: false,
            hashtagString: ""
        )
    }
    
    func saveAsset(asset: OptographAsset) {
        switch asset {
        case .LeftImage(let data):
            data.writeToFile("\(StaticPath)/\(leftTextureAssetId).jpg", atomically: true)
        case .RightImage(let data):
            data.writeToFile("\(StaticPath)/\(rightTextureAssetId).jpg", atomically: true)
        case .PreviewImage(let data):
            data.writeToFile("\(StaticPath)/\(previewAssetId).jpg", atomically: true)
        }
    }
    
    mutating func publish() -> SignalProducer<Optograph, ApiError> {
        assert(!isPublished)
        
        let parameters = SignalProducer<[String: AnyObject], ApiError> { sink, disposable in
            var parameters = Mapper().toJSON(self)
            
            parameters["stitcher_version"] = StitcherVersion
            parameters["left_texture_asset"] = NSData(contentsOfFile: "\(StaticPath)/\(self.leftTextureAssetId).jpg")!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
            parameters["right_texture_asset"] = NSData(contentsOfFile: "\(StaticPath)/\(self.rightTextureAssetId).jpg")!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
            parameters["preview_asset"] = NSData(contentsOfFile: "\(StaticPath)/\(self.previewAssetId).jpg")!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
            
            sendNext(sink, parameters)
            sendCompleted(sink)
            
            disposable.addDisposable {}
        }
        
        return parameters.flatMap(.Latest) { ApiService.post("optographs", parameters: $0) }
            .on(completed: {
                self.isPublished = true
                
                try! DatabaseService.defaultConnection.run(
                    OptographTable.filter(OptographSchema.id ==- self.id).update(
                        OptographSchema.isPublished <-- self.isPublished
                    )
                )
            })
    }
}

extension Optograph: Mappable {
    
    init?(_ map: Map){
        self = Optograph.newInstance()
    }
    
    mutating func mapping(map: Map) {
        if map.mappingType == .FromJSON {
            isStitched = true
            isPublished = true
        }
        
        id                  <- map["id"]
        text                <- map["text"]
        person              <- map["person"]
        createdAt           <- (map["created_at"], NSDateTransform())
        isStarred           <- map["is_starred"]
        starsCount          <- map["stars_count"]
        commentsCount       <- map["comments_count"]
        viewsCount          <- map["views_count"]
        location            <- map["location"]
        previewAssetId      <- map["preview_asset_id"]
        leftTextureAssetId  <- map["left_texture_asset_id"]
        rightTextureAssetId <- map["right_texture_asset_id"]
        isStaffPick         <- map["is_staff_pick"]
        hashtagString       <- map["hashtag_string"]
    }
    
}

extension Optograph: SQLiteModel {
    
    static func schema() -> ModelSchema {
        return OptographSchema
    }
    
    static func table() -> SQLiteTable {
        return OptographTable
    }
    
    static func fromSQL(row: SQLiteRow) -> Optograph {
        return Optograph(
            id: row[OptographSchema.id],
            text: row[OptographSchema.text],
            person: Person.newInstance(),
            createdAt: row[OptographSchema.createdAt],
            deleted: row[OptographSchema.deleted],
            isStarred: row[OptographSchema.isStarred],
            starsCount: row[OptographSchema.starsCount],
            commentsCount: row[OptographSchema.commentsCount],
            viewsCount: row[OptographSchema.viewsCount],
            location: Location.newInstance(),
            isStitched: row[OptographSchema.isStitched],
            isPublished: row[OptographSchema.isPublished],
            previewAssetId: row[OptographSchema.previewAssetId],
            leftTextureAssetId: row[OptographSchema.leftTextureAssetId],
            rightTextureAssetId: row[OptographSchema.rightTextureAssetId],
            isStaffPick: row[OptographSchema.isStaffPick],
            hashtagString: row[OptographSchema.hashtagString]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
        return [
            OptographSchema.id <-- id,
            OptographSchema.text <-- text,
            OptographSchema.personId <-- person.id,
            OptographSchema.createdAt <-- createdAt,
            OptographSchema.deleted <-- deleted,
            OptographSchema.isStarred <-- isStarred,
            OptographSchema.starsCount <-- starsCount,
            OptographSchema.commentsCount <-- commentsCount,
            OptographSchema.viewsCount <-- viewsCount,
            OptographSchema.locationId <-- location.id,
            OptographSchema.isStitched <-- isStitched,
            OptographSchema.isPublished <-- isPublished,
            OptographSchema.previewAssetId <-- previewAssetId,
            OptographSchema.leftTextureAssetId <-- leftTextureAssetId,
            OptographSchema.rightTextureAssetId <-- rightTextureAssetId,
            OptographSchema.isStaffPick <-- isStaffPick,
            OptographSchema.hashtagString <-- hashtagString,
        ]
    }
    
}
//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper
import ReactiveCocoa
import WebImage

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
    var deletedAt: NSDate?
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
    
    var leftTextureAssetURL: String {
        return "\(S3URL)/original/\(leftTextureAssetId).jpg"
    }
    
    var rightTextureAssetURL: String {
        return "\(S3URL)/original/\(rightTextureAssetId).jpg"
    }
    
    var previewAssetURL: String {
        return "\(S3URL)/original/\(previewAssetId).jpg"
    }
    
    static func newInstance() -> Optograph {
        return Optograph(
            id: uuid(),
            text: "",
            person: Person.newInstance(),
            createdAt: NSDate(),
            deletedAt: nil,
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
            SDImageCache.sharedImageCache().storeImage(UIImage(data: data)!, forKey: leftTextureAssetURL, toDisk: true)
        case .RightImage(let data):
            SDImageCache.sharedImageCache().storeImage(UIImage(data: data)!, forKey: rightTextureAssetURL, toDisk: true)
        case .PreviewImage(let data):
            SDImageCache.sharedImageCache().storeImage(UIImage(data: data)!, forKey: previewAssetURL, toDisk: true)
        }
    }
    
    mutating func publish() -> SignalProducer<Optograph, ApiError> {
        assert(!isPublished)
        
        return SDWebImageManager.sharedManager().downloadDataForURL(leftTextureAssetURL)
            .combineLatestWith(SDWebImageManager.sharedManager().downloadDataForURL(rightTextureAssetURL))
            .combineLatestWith(SDWebImageManager.sharedManager().downloadDataForURL(previewAssetURL))
            .map { ($0.0, $0.1, $1) }
            .map { (left, right, preview) -> [String: AnyObject] in
                var parameters = Mapper().toJSON(self)
                
                parameters["stitcher_version"] = StitcherVersion
                parameters["left_texture_asset"] = left.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                parameters["right_texture_asset"] = right.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                parameters["preview_asset"] = preview.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                
                return parameters
            }
            .mapError { _ in ApiError.Nil }
            .flatMap(.Latest) { ApiService.post("optographs", parameters: $0) }
            .on(completed: {
                self.isPublished = true
                
                try! DatabaseService.defaultConnection.run(
                    OptographTable.filter(OptographSchema.id ==- self.id).update(
                        OptographSchema.isPublished <-- self.isPublished
                    )
                )
            })
    }
    
    mutating func delete() -> SignalProducer<EmptyResponse, ApiError> {
        var signalProducer: SignalProducer<EmptyResponse, ApiError>
        if isPublished {
            signalProducer = ApiService<EmptyResponse>.delete("optographs/\(id)")
        } else {
            signalProducer = SignalProducer { sink, disposable in
                disposable.addDisposable {}
                sendCompleted(sink)
            }
        }
        
        return signalProducer
            .on(completed: {
                self.deletedAt = NSDate()
                try! self.insertOrUpdate()
            })
    }
    
    func report() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("optographs/\(id)/report")
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
        deletedAt           <- (map["deleted_at"], NSDateTransform())
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
            deletedAt: row[OptographSchema.deletedAt],
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
            OptographSchema.deletedAt <-- deletedAt,
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

extension Optograph: Equatable {}

func ==(lhs: Optograph, rhs: Optograph) -> Bool {
    return lhs.isStitched == rhs.isStitched
        && lhs.starsCount == rhs.starsCount
        && lhs.isPublished == rhs.isPublished
}
//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ObjectMapper
import ReactiveCocoa
import Kingfisher

enum OptographAsset {
    case PreviewImage(NSData)
    case LeftImage(NSData)
    case RightImage(NSData)
}

typealias HashtagStrings = Array<String>

struct CubeTextureUploadStatus: SQLiteValue {
    var status: [Bool] = [false, false, false, false, false, false]
    
//    subscript(index: Int) -> Bool {
//        get { return status[index] }
//        set(newVal) { status[index] = newVal }
//    }
    
    static var declaredDatatype: String {
        return Int64.declaredDatatype
    }
    
    static func fromDatatypeValue(datatypeValue: Int64) -> CubeTextureUploadStatus {
        var status = CubeTextureUploadStatus()
        var val = datatypeValue
        for i in 0..<6 {
            status.status[i] = val % 2 == 1
            val /= 2
        }
        return status
    }
    
    var datatypeValue: Int64 {
        return (0..<6)
            .filter { self.status[$0] }
            .reduce(0) { Int64(pow(2, Double($1))) + $0 }
    }
}

struct Optograph: DeletableModel {
    
    var ID: UUID
    var text: String
    var person: Person
    var createdAt: NSDate
    var deletedAt: NSDate?
    var isStarred: Bool
    var starsCount: Int
    var commentsCount: Int
    var viewsCount: Int
    var location: Location?
    var isPrivate: Bool
    var isStitched: Bool
    var isSubmitted: Bool
    var isPublished: Bool
    var stitcherVersion: String
    var shareAlias: String
    var leftCubeTextureUploadStatus: CubeTextureUploadStatus?
    var rightCubeTextureUploadStatus: CubeTextureUploadStatus?
    var isStaffPick: Bool
    var hashtagString: String
    var isInFeed: Bool
    var directionPhi: Double
    var directionTheta: Double
    var postFacebook: Bool
    var postTwitter: Bool
    var postInstagram: Bool
    var shouldBePublished: Bool
    
    static func newInstance() -> Optograph {
        return Optograph(
            ID: uuid(),
            text: "",
            person: Person.newInstance(),
            createdAt: NSDate(),
            deletedAt: nil,
            isStarred: false,
            starsCount: 0,
            commentsCount: 0,
            viewsCount: 0,
            location: nil,
            isPrivate: false,
            isStitched: false,
            isSubmitted: false,
            isPublished: false,
            stitcherVersion: "",
            shareAlias: "",
            leftCubeTextureUploadStatus: nil,
            rightCubeTextureUploadStatus: nil,
            isStaffPick: false,
            hashtagString: "",
            isInFeed: false,
            directionPhi: 0,
            directionTheta: 0,
            postFacebook: false,
            postTwitter: false,
            postInstagram: false,
            shouldBePublished: false
        )
    }
    
    func saveAsset(asset: OptographAsset) {
        
//                    return ApiService<EmptyResponse>.upload("optographs/\(optograph.ID)/upload-asset", multipartFormData: { form in
//                        form.appendBodyPart(data: "placeholder".dataUsingEncoding(NSUTF8StringEncoding)!, name: "key")
//                        form.appendBodyPart(data: optograph.placeholderTextureAssetID.dataUsingEncoding(NSUTF8StringEncoding)!, name: "asset_id")
//                        form.appendBodyPart(data: UIImageJPEGRepresentation(image, 0.7)!, name: "asset", fileName: "placeholder.jpg", mimeType: "image/jpeg")
//                    })
//        switch asset {
//        case .LeftImage(let data):
//            let image = UIImage(data: data)!
//            ImageCache.defaultCache.storeImage(image, forKey: ImageURL(leftTextureAssetID))
//            // needed for feed
////            ImageCache.defaultCache.storeImage(image.resized(.Width, value: 2048 * UIScreen.mainScreen().scale), forKey: ImageURL(leftTextureAssetID, width: 2048))
//            ImageCache.defaultCache.storeImage(image.resized(.Width, value: 4096), forKey: ImageURL(leftTextureAssetID, width: Int(4096 / UIScreen.mainScreen().scale)))
//        case .RightImage(let data):
//            ImageCache.defaultCache.storeImage(UIImage(data: data)!, forKey: ImageURL(rightTextureAssetID))
//        case .PreviewImage(let data):
//            ImageCache.defaultCache.storeImage(UIImage(data: data)!, forKey: ImageURL(placeholderTextureAssetID))
//            // needs all different sizes
//            ImageCache.defaultCache.storeImage(UIImage(data: data)!, forKey: ImageURL(placeholderTextureAssetID, fullDimension: .Width))
//            ImageCache.defaultCache.storeImage(UIImage(data: data)!, forKey: ImageURL(placeholderTextureAssetID, width: 32, height: 40))
//        }
    }
    
//    mutating func publish() -> SignalProducer<Optograph, ApiError> {
//        assert(!isPublished)
    
//        return KingfisherManager.sharedManager.downloader.downloadDataForURL(ImageURL(leftTextureAssetID))
//            .combineLatestWith(KingfisherManager.sharedManager.downloader.downloadDataForURL(ImageURL(rightTextureAssetID)))
//            .combineLatestWith(KingfisherManager.sharedManager.downloader.downloadDataForURL(ImageURL(placeholderTextureAssetID)))
//            .map { ($0.0, $0.1, $1) }
//            .map { (left, right, preview) -> [String: AnyObject] in
//                var parameters = Mapper().toJSON(self)
//                
//                parameters["left_texture_asset"] = left.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
//                parameters["right_texture_asset"] = right.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
//                parameters["preview_asset"] = preview.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
//                
//                return parameters
//            }
//            .mapError { _ in ApiError.Nil }
//            .flatMap(.Latest) { ApiService.post("optographs", parameters: $0) }
//            .on(completed: {
//                self.isPublished = true
//                
//                try! DatabaseService.defaultConnection.run(
//                    OptographTable.filter(OptographSchema.ID ==- self.ID).update(
//                        OptographSchema.isPublished <-- self.isPublished
//                    )
//                )
//            })
//    }
    
    mutating func delete() -> SignalProducer<EmptyResponse, ApiError> {
        var signalProducer: SignalProducer<EmptyResponse, ApiError>
        if isPublished {
            signalProducer = ApiService<EmptyResponse>.delete("optographs/\(ID)")
        } else {
            signalProducer = SignalProducer { sink, disposable in
                disposable.addDisposable {}
                sink.sendCompleted()
            }
        }
        
        return signalProducer
            .on(completed: {
                self.deletedAt = NSDate()
                try! self.insertOrUpdate()
            })
    }
    
    func report() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("optographs/\(ID)/report")
    }
}

func ==(lhs: Optograph, rhs: Optograph) -> Bool {
    guard let lhsLocation = lhs.location, rhsLocation = rhs.location else {
        return lhs.location == nil && rhs.location == nil
    }
    
    return lhs.ID == rhs.ID
        && lhs.isStitched == rhs.isStitched
        && lhs.starsCount == rhs.starsCount
        && lhs.isPublished == rhs.isPublished
        && lhs.isStarred == rhs.isStarred
        && lhs.starsCount == rhs.starsCount
        && lhs.person == rhs.person
        && lhsLocation == rhsLocation
}

extension Optograph: Mappable {
    
    init?(_ map: Map){
        self = Optograph.newInstance()
    }
    
    mutating func mapping(map: Map) {
        if map.mappingType == .FromJSON {
            isStitched = true
            isPublished = true
            isSubmitted = true
        }
        
        ID                          <- map["id"]
        text                        <- map["text"]
        person                      <- map["person"]
        createdAt                   <- (map["created_at"], NSDateTransform())
        deletedAt                   <- (map["deleted_at"], NSDateTransform())
        isStarred                   <- map["is_starred"]
        isPrivate                   <- map["is_private"]
        stitcherVersion             <- map["stitcher_version"]
        shareAlias                  <- map["share_alias"]
        starsCount                  <- map["stars_count"]
        commentsCount               <- map["comments_count"]
        viewsCount                  <- map["views_count"]
        location                    <- map["location"]
        isStaffPick                 <- map["is_staff_pick"]
        hashtagString               <- map["hashtag_string"]
        directionPhi                <- map["direction_phi"]
        directionTheta              <- map["direction_theta"]
        
        if person.displayName.isEmpty {
            print(self)
        }
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
        let leftCubeTextureUploadStatus = row.get(OptographSchema.leftCubeTextureUploadStatus)
        let rightCubeTextureUploadStatus = row.get(OptographSchema.rightCubeTextureUploadStatus)
        
        return Optograph(
            ID: row[OptographSchema.ID],
            text: row[OptographSchema.text],
            person: Person.newInstance(),
            createdAt: row[OptographSchema.createdAt],
            deletedAt: row[OptographSchema.deletedAt],
            isStarred: row[OptographSchema.isStarred],
            starsCount: row[OptographSchema.starsCount],
            commentsCount: row[OptographSchema.commentsCount],
            viewsCount: row[OptographSchema.viewsCount],
            location: nil,
            isPrivate: row[OptographSchema.isPrivate],
            isStitched: row[OptographSchema.isStitched],
            isSubmitted: row[OptographSchema.isSubmitted],
            isPublished: row[OptographSchema.isPublished],
            stitcherVersion: row[OptographSchema.stitcherVersion],
            shareAlias: row[OptographSchema.shareAlias],
            leftCubeTextureUploadStatus: leftCubeTextureUploadStatus,
            rightCubeTextureUploadStatus: rightCubeTextureUploadStatus,
            isStaffPick: row[OptographSchema.isStaffPick],
            hashtagString: row[OptographSchema.hashtagString],
            isInFeed: row[OptographSchema.isInFeed],
            directionPhi: row[OptographSchema.directionPhi],
            directionTheta: row[OptographSchema.directionTheta],
            postFacebook: row[OptographSchema.postFacebook],
            postTwitter: row[OptographSchema.postTwitter],
            postInstagram: row[OptographSchema.postInstagram],
            shouldBePublished: row[OptographSchema.shouldBePublished]
        )
    }
    
    func toSQL() -> [SQLiteSetter] {
//        print("in feed \(isInFeed)")
        return [
            OptographSchema.ID <-- ID,
            OptographSchema.text <-- text,
            OptographSchema.personID <-- person.ID,
            OptographSchema.createdAt <-- createdAt,
            OptographSchema.deletedAt <-- deletedAt,
            OptographSchema.isStarred <-- isStarred,
            OptographSchema.starsCount <-- starsCount,
            OptographSchema.commentsCount <-- commentsCount,
            OptographSchema.viewsCount <-- viewsCount,
            OptographSchema.locationID <-- location?.ID,
            OptographSchema.isPrivate <-- isPrivate,
            OptographSchema.isStitched <-- isStitched,
            OptographSchema.isSubmitted <-- isSubmitted,
            OptographSchema.isPublished <-- isPublished,
            OptographSchema.stitcherVersion <-- stitcherVersion,
            OptographSchema.shareAlias <-- shareAlias,
            OptographSchema.leftCubeTextureUploadStatus <-- leftCubeTextureUploadStatus,
            OptographSchema.rightCubeTextureUploadStatus <-- rightCubeTextureUploadStatus,
            OptographSchema.isStaffPick <-- isStaffPick,
            OptographSchema.hashtagString <-- hashtagString,
            OptographSchema.isInFeed <-- isInFeed,
            OptographSchema.directionPhi <-- directionPhi,
            OptographSchema.directionTheta <-- directionTheta,
            OptographSchema.postFacebook <-- postFacebook,
            OptographSchema.postTwitter <-- postTwitter,
            OptographSchema.postInstagram <-- postInstagram,
            OptographSchema.shouldBePublished <-- shouldBePublished,
        ]
    }
    
}

//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

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
    
    var completed: Bool {
        return status.reduce(true, combine: and)
    }
    
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
    var personID: UUID
    var createdAt: NSDate
    var updatedAt: NSDate
    var deletedAt: NSDate?
    var isStarred: Bool
    var starsCount: Int
    var commentsCount: Int
    var viewsCount: Int
    var locationID: UUID?
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
            personID: "",
            createdAt: NSDate(),
            updatedAt: NSDate(),
            deletedAt: nil,
            isStarred: false,
            starsCount: 0,
            commentsCount: 0,
            viewsCount: 0,
            locationID: nil,
            isPrivate: false,
            isStitched: true,
            isSubmitted: true,
            isPublished: true,
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
    
    mutating func delete() {
        deletedAt = NSDate()
    }
    
    func report() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("optographs/\(ID)/report")
    }
    
}

func ==(lhs: Optograph, rhs: Optograph) -> Bool {
    guard let lhsLocationID = lhs.locationID, rhsLocationID = rhs.locationID else {
        return lhs.locationID == nil && rhs.locationID == nil
    }
    
    return lhs.ID == rhs.ID
        && lhs.isStitched == rhs.isStitched
        && lhs.starsCount == rhs.starsCount
        && lhs.isPublished == rhs.isPublished
        && lhs.isStarred == rhs.isStarred
        && lhs.starsCount == rhs.starsCount
        && lhs.personID == rhs.personID
        && lhsLocationID == rhsLocationID
}

extension Optograph: MergeApiModel {
    typealias AM = OptographApiModel
    
    mutating func mergeApiModel(apiModel: AM) {
        ID = apiModel.ID
        text = apiModel.text
        personID = apiModel.person.ID
        createdAt = apiModel.createdAt
        updatedAt = apiModel.updatedAt
        deletedAt = apiModel.deletedAt
        isStarred = apiModel.isStarred
        isPrivate = apiModel.isPrivate
        stitcherVersion = apiModel.stitcherVersion
        shareAlias = apiModel.shareAlias
        starsCount = apiModel.starsCount
        commentsCount = apiModel.commentsCount
        viewsCount = apiModel.viewsCount
        locationID = apiModel.location?.ID
        isStaffPick = apiModel.isStaffPick
        directionPhi = apiModel.directionPhi
        directionTheta = apiModel.directionTheta
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
            personID: row[OptographSchema.personID],
            createdAt: row[OptographSchema.createdAt],
            updatedAt: row[OptographSchema.updatedAt],
            deletedAt: row[OptographSchema.deletedAt],
            isStarred: row[OptographSchema.isStarred],
            starsCount: row[OptographSchema.starsCount],
            commentsCount: row[OptographSchema.commentsCount],
            viewsCount: row[OptographSchema.viewsCount],
            locationID: row[OptographSchema.locationID],
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
        return [
            OptographSchema.ID <-- ID,
            OptographSchema.text <-- text,
            OptographSchema.personID <-- personID,
            OptographSchema.createdAt <-- createdAt,
            OptographSchema.updatedAt <-- updatedAt,
            OptographSchema.deletedAt <-- deletedAt,
            OptographSchema.isStarred <-- isStarred,
            OptographSchema.starsCount <-- starsCount,
            OptographSchema.commentsCount <-- commentsCount,
            OptographSchema.viewsCount <-- viewsCount,
            OptographSchema.locationID <-- locationID,
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

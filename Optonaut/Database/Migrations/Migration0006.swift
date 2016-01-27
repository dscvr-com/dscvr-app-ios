//
//  Migration0006.swift
//  Optonaut
//
//  Created by Johannes Schickling on 27/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

func migration0006(db: Connection) throws {
    try db.run(OptographTable.addColumn(OptographSchema.isInFeed, defaultValue: false))
    try db.run(OptographTable.addColumn(OptographSchema.directionPhi, defaultValue: 0))
    try db.run(OptographTable.addColumn(OptographSchema.directionTheta, defaultValue: 0))
    try db.run(OptographTable.addColumn(OptographSchema.leftCubeTextureStatusUpload, defaultValue: nil))
    try db.run(OptographTable.addColumn(OptographSchema.rightCubeTextureStatusUpload, defaultValue: nil))
    try db.run(OptographTable.addColumn(OptographSchema.leftCubeTextureStatusSave, defaultValue: nil))
    try db.run(OptographTable.addColumn(OptographSchema.rightCubeTextureStatusSave, defaultValue: nil))
    try db.run(OptographTable.addColumn(OptographSchema.postFacebook, defaultValue: false))
    try db.run(OptographTable.addColumn(OptographSchema.postTwitter, defaultValue: false))
    try db.run(OptographTable.addColumn(OptographSchema.postInstagram, defaultValue: false))
    try db.run(OptographTable.addColumn(OptographSchema.shouldBePublished, defaultValue: false))
    try db.run(OptographTable.addColumn(OptographSchema.isSubmitted, defaultValue: true))
    
    try db.run(LocationTable.addColumn(LocationSchema.countryShort, defaultValue: ""))
    try db.run(LocationTable.addColumn(LocationSchema.place, defaultValue: ""))
    try db.run(LocationTable.addColumn(LocationSchema.region, defaultValue: ""))
    try db.run(LocationTable.addColumn(LocationSchema.POI, defaultValue: false))
    
    let aLongTimeAgo = NSDate(timeIntervalSince1970: 0)
    
    try db.run(ActivityTable.addColumn(ActivitySchema.updatedAt, defaultValue: aLongTimeAgo))
    try db.run(CommentTable.addColumn(CommentSchema.updatedAt, defaultValue: aLongTimeAgo))
    try db.run(HashtagTable.addColumn(HashtagSchema.createdAt, defaultValue: aLongTimeAgo))
    try db.run(HashtagTable.addColumn(HashtagSchema.updatedAt, defaultValue: aLongTimeAgo))
    try db.run(LocationTable.addColumn(LocationSchema.updatedAt, defaultValue: aLongTimeAgo))
    try db.run(OptographTable.addColumn(OptographSchema.updatedAt, defaultValue: aLongTimeAgo))
    try db.run(PersonTable.addColumn(PersonSchema.updatedAt, defaultValue: aLongTimeAgo))
}

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
    try db.run(OptographTable.addColumn(OptographSchema.placeholderTextureAssetID, defaultValue: ""))
    
    try db.run(LocationTable.addColumn(LocationSchema.countryShort, defaultValue: ""))
    try db.run(LocationTable.addColumn(LocationSchema.place, defaultValue: ""))
    try db.run(LocationTable.addColumn(LocationSchema.region, defaultValue: ""))
    try db.run(LocationTable.addColumn(LocationSchema.POI, defaultValue: false))
}

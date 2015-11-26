//
//  Migration0004.swift
//  Optonaut
//
//  Created by Johannes Schickling on 26/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

func migration0004(db: Connection) throws {
    try db.run(OptographTable.addColumn(OptographSchema.stitcherVersion, defaultValue: StitcherVersion))
}
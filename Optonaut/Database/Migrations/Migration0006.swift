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
}

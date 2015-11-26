//
//  Migration0003.swift
//  Optonaut
//
//  Created by Johannes Schickling on 26/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

func migration0003(db: Connection) throws {
    try db.run(OptographTable.addColumn(OptographSchema.isPrivate, defaultValue: false))
}
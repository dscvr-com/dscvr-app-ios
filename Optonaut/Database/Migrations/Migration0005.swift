//
//  Migration0005.swift
//  Optonaut
//
//  Created by Johannes Schickling on 27/11/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

func migration0005(db: Connection) throws {
    try db.run(OptographTable.addColumn(OptographSchema.shareAlias, defaultValue: ""))
}
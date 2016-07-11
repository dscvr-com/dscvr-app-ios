//
//  Migration0007.swift
//  Iam360
//
//  Created by robert john alkuino on 6/28/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import SQLite

func migration0007(db: Connection) throws {
    try db.run(OptographTable.addColumn(OptographSchema.ringCount, defaultValue: ""))
}

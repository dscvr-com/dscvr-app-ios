//
//  Migration0008.swift
//  DSCVR
//
//  Created by robert john alkuino on 7/18/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import SQLite

func migration0008(db: Connection) throws {
    try db.run(PersonTable.addColumn(PersonSchema.eliteStatus, defaultValue: 0))
}


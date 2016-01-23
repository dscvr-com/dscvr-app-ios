//
//  Location.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import SQLite

struct LocationSchemaType: ModelSchema {
    let ID = Expression<UUID>("location_id")
    let createdAt = Expression<NSDate>("location_created_at")
    let updatedAt = Expression<NSDate>("location_updated_at")
    let text = Expression<String>("location_text")
    let country = Expression<String>("location_country")
    let countryShort = Expression<String>("location_country_short")
    let place = Expression<String>("location_place")
    let region = Expression<String>("location_region")
    let POI = Expression<Bool>("location_poi")
    let latitude = Expression<Double>("location_latitude")
    let longitude = Expression<Double>("location_longitude")
}

let LocationSchema = LocationSchemaType()
let LocationTable = Table("location")
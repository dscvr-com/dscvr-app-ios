//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ReactiveSwift

enum OptographAsset {
    case previewImage(Data)
    case leftImage(Data)
    case rightImage(Data)
}

typealias HashtagStrings = Array<String>


struct Optograph : DeletableModel {
    
    var ID: UUID
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var isStitched: Bool
    var stitcherVersion: String
    var directionPhi: Double
    var directionTheta: Double
    var ringCount: Int
    
    static func newInstance() -> Optograph {
        return Optograph(
            ID: uuid(),
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            isStitched: true,
            stitcherVersion: "",
            directionPhi: 0,
            directionTheta: 0,
            ringCount: 1
        )
    }
    
}

func ==(lhs: Optograph, rhs: Optograph) -> Bool {
    return lhs.ID                             == rhs.ID
        && lhs.createdAt                      == rhs.createdAt
        && lhs.updatedAt                      == rhs.updatedAt
        && lhs.deletedAt                      == rhs.deletedAt
        && lhs.isStitched                     == rhs.isStitched
        && lhs.stitcherVersion                == rhs.stitcherVersion
}


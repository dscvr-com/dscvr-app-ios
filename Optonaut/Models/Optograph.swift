//
//  Optograph.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import ReactiveSwift
//import Kingfisher

enum OptographAsset {
    case previewImage(Data)
    case leftImage(Data)
    case rightImage(Data)
}

typealias HashtagStrings = Array<String>


struct Optograph {
    
    var ID: UUID
    var createdAt: Date
    var updatedAt: Date
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
        && lhs.isStitched                     == rhs.isStitched
        && lhs.stitcherVersion                == rhs.stitcherVersion
}

extension Optograph: MergeApiModel {
    typealias AM = OptographApiModel
    
    mutating func mergeApiModel(_ apiModel: AM) {
        ID = apiModel.ID
        createdAt = apiModel.createdAt
        updatedAt = apiModel.updatedAt
        stitcherVersion = apiModel.stitcherVersion
        directionPhi = apiModel.directionPhi
        directionTheta = apiModel.directionTheta
    }
}


//
//  NSURLExtensions.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/15/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

enum ApplicationURLData {
    case optograph(UUID)
    case `nil`
}

extension URL {
    
    // URL format: optonaut://optographs/13EF21D7-F175-45E7-8876-4B205225C221
    var applicationURLData: ApplicationURLData {
        get {
            let uuidPattern = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
            if let uuid = path.components(separatedBy: "/").last, let resourceType = host, uuid.range(of: uuidPattern, options: .regularExpression) != nil {
                switch resourceType {
                case "optographs": return .optograph(uuid)
                default: ()
                }
            }
            
            return .nil
        }
    }
    
}

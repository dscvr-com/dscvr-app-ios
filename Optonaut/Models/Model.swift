//
//  Model.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/1/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import RealmSwift

protocol Model {
    var createdAt: NSDate { get set }
}

extension Object {

    func values(keys: [String]) -> [String: AnyObject] {
        return keys.toDictionary { ($0, self.valueForKeyPath($0)!) }
    }
    
}

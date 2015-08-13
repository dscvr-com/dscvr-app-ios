//
//  Model.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/1/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import RealmSwift

protocol Model: Hashable {
    var id: Int { get set }
    var createdAt: NSDate { get set }
}

extension Model where Self: Object {
    
    var hashValue: Int {
        get {
            return id.hashValue
        }
    }

    func values(keys: [String]) -> [String: AnyObject] {
        return keys.toDictionary { ($0, self.valueForKeyPath($0)!) }
    }
    
}

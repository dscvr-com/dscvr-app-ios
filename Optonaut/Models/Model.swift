//
//  Model.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/1/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

typealias UUID = String

protocol Model {
    var id: UUID { get set }
    var createdAt: NSDate { get set }
}

extension Array where Element: Model {
    
    mutating func orderedInsert(newModel: Element, withOrder order: NSComparisonResult) {
        // replace if already in array
        if let index = indexOf({ $0.id == newModel.id }) {
            self[index] = newModel
            return
        }
        
        for (index, model) in self.enumerate() {
            if model.createdAt.compare(newModel.createdAt) != order {
                insert(newModel, atIndex: index)
                return
            }
        }
        
        // append to end as fallback
        append(newModel)
    }
    
}

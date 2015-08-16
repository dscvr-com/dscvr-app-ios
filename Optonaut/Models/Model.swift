//
//  Model.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/1/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

protocol Model {
    var id: Int { get set }
    var createdAt: NSDate { get set }
}

extension Array where Element: Model {
    
    mutating func orderedInsert(newModel: Element, withOrder order: NSComparisonResult) {
        // check if already in array
        if contains({ $0.id == newModel.id }) {
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

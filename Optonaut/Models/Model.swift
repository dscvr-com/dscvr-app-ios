//
//  Model.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/1/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

typealias UUID = String

protocol ApiModel {
    var ID: UUID { get }
    var createdAt: NSDate { get }
    var updatedAt: NSDate { get }
}

protocol Model {
    var ID: UUID { get set }
    var createdAt: NSDate { get set }
    var updatedAt: NSDate { get set }
}

protocol MergeApiModel: Model {
    typealias AM: ApiModel
    
    mutating func mergeApiModel(apiModel: AM)
    static func newInstance() -> Self
    static func fromApiModel(apiModel: AM) -> Self
}

extension MergeApiModel {
    static func fromApiModel(apiModel: AM) -> Self {
        var model = newInstance()
        model.mergeApiModel(apiModel)
        return model
    }
}

protocol DeletableModel: Model, Equatable {
    var deletedAt: NSDate? { get set }
}

extension Array where Element: Model {
    
    mutating func orderedInsert(newModel: Element, withOrder order: NSComparisonResult) {
        // replace if already in array
        if let index = indexOf({ $0.ID == newModel.ID }) {
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
    
    func orderedMerge(newModels: Array, withOrder order: NSComparisonResult) -> Array {
        var newArray = self
        
        for newModel in newModels {
            newArray.orderedInsert(newModel, withOrder: order)
        }
        
        return newArray
    }
    
}
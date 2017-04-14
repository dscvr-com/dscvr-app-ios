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
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

protocol Model {
    var ID: UUID { get set }
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}

protocol MergeApiModel: Model {
    associatedtype AM: ApiModel
    
    mutating func mergeApiModel(_ apiModel: AM)
    static func newInstance() -> Self
    static func fromApiModel(_ apiModel: AM) -> Self
}

extension MergeApiModel {
    static func fromApiModel(_ apiModel: AM) -> Self {
        var model = newInstance()
        model.mergeApiModel(apiModel)
        return model
    }
}

protocol DeletableModel: Model, Equatable {
    var deletedAt: Date? { get set }
}

extension Array where Element: Model {
    
    mutating func orderedInsert(_ newModel: Element, withOrder order: ComparisonResult) {
        // replace if already in array
        if let index = index(where: { $0.ID == newModel.ID }) {
            self[index] = newModel
            return
        }
        
        for (index, model) in self.enumerated() {
            if model.createdAt.compare(newModel.createdAt) != order {
                insert(newModel, at: index)
                return
            }
        }
        
        // append to end as fallback
        append(newModel)
    }
    
    func orderedMerge(_ newModels: Array, withOrder order: ComparisonResult) -> Array {
        var newArray = self
        
        for newModel in newModels {
            newArray.orderedInsert(newModel, withOrder: order)
        }
        
        return newArray
    }
    
}

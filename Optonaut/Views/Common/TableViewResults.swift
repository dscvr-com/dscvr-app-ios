//
//  TableViewResults.swift
//  Optonaut
//
//  Created by Johannes Schickling on 28/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation

struct TableViewResults<T: DeletableModel> {
    let insert: [Int]
    let update: [Int]
    let delete: [Int]
    let models: [T]
    let changed: Bool
    
    static func empty() -> TableViewResults<T> {
        return TableViewResults<T>(insert: [], update: [], delete: [], models: [], changed: false)
    }
    
    func merge(newModels: [T], deleteOld: Bool) -> TableViewResults<T> {

        var models = self.models
        
        var delete: [Int] = []
        
        for deletedModel in newModels.filter({ $0.deletedAt != nil }) {
            if let index = models.indexOf({ $0.ID == deletedModel.ID }) {
                delete.append(index)
            }
        }
        
        if deleteOld {
            for (index, model) in models.enumerate() {
                if newModels.indexOf({ $0.ID == model.ID }) == nil {
                    delete.append(index)
                }
            }
        }
        for deleteIndex in delete.sort().reverse() {
            models.removeAtIndex(deleteIndex)
        }
        
        var update: [Int] = []
        var exclusiveNewModels: [T] = []
        for newModel in newModels.filter({ $0.deletedAt == nil }) {
//            if let index = models.indexOf({ $0.ID == newModel.ID && $0.storyId == newModel.storyId}) {
//                if models[index] != newModel {
//                    update.append(index)
//                    models[index] = newModel
//                }
//            } else {
//                exclusiveNewModels.append(newModel)
//            }
            //exclusiveNewModels.append(newModel)
        }
        
        var insert: [Int] = []
        for newModel in exclusiveNewModels.sort({ $0.createdAt > $1.createdAt }) {
            if let index = models.indexOf({ $0.createdAt < newModel.createdAt }) {
                insert.append(index)
                models.insert(newModel, atIndex: index)
            } else {
                insert.append(models.count)
                models.append(newModel)
            }
        }
        
        let changed = !insert.isEmpty || !update.isEmpty || !delete.isEmpty
        
        return TableViewResults(insert: insert, update: update, delete: delete, models: models, changed: changed)
    }
    func mergeForNotification(newModels: [T], deleteOld: Bool) -> TableViewResults<T> {
        
        var models = self.models
        
        var delete: [Int] = []
        
        for deletedModel in newModels.filter({ $0.deletedAt != nil }) {
            if let index = models.indexOf({ $0.ID == deletedModel.ID }) {
                delete.append(index)
            }
        }
        
        if deleteOld {
            for (index, model) in models.enumerate() {
                if newModels.indexOf({ $0.ID == model.ID }) == nil {
                    delete.append(index)
                }
            }
        }
        for deleteIndex in delete.sort().reverse() {
            models.removeAtIndex(deleteIndex)
        }
        
        var update: [Int] = []
        var exclusiveNewModels: [T] = []
        for newModel in newModels {
            if let index = models.indexOf({ $0.ID == newModel.ID }) {
                if models[index] != newModel {
                    update.append(index)
                    models[index] = newModel
                }
            } else {
                exclusiveNewModels.append(newModel)
            }
        }
        
        var insert: [Int] = []
        for newModel in exclusiveNewModels.sort({ $0.createdAt > $1.createdAt }) {
            if let index = models.indexOf({ $0.createdAt < newModel.createdAt }) {
                insert.append(index)
                models.insert(newModel, atIndex: index)
            } else {
                insert.append(models.count)
                models.append(newModel)
            }
        }
        
        let changed = !insert.isEmpty || !update.isEmpty || !delete.isEmpty
        
        return TableViewResults(insert: insert, update: update, delete: delete, models: models, changed: changed)
    }
}

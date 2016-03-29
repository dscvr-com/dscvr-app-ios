//
//  Models.swift
//  Optonaut
//
//  Created by Johannes Schickling on 22/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Result

class ModelBox<M: Model> {
    
    typealias ModelType = M
    
    // parent relationship
    private weak var cache: ModelCache<ModelType>?
    
    var model: ModelType
    
    var producer: SignalProducer<ModelType, NoError> {
        return property.producer
    }
    
    private let property: MutableProperty<ModelType>
    
    private init(model: ModelType) {
        self.model = model
        property = MutableProperty(model)
    }
    
    func update(closure: ModelBox -> ()) {
        objc_sync_enter(self)
        closure(self)
        dispatch_async(dispatch_get_main_queue()) {
            self.property.value = self.model
        }
        objc_sync_exit(self)
    }
    
    func replace(model: ModelType) {
        assert(model.ID == self.model.ID)
        objc_sync_enter(self)
        self.model = model
        dispatch_async(dispatch_get_main_queue()) {
            self.property.value = model
        }
        objc_sync_exit(self)
    }
    
    func removeFromCache() {
        cache?.forget(model.ID)
    }
    
}

extension ModelBox where M: SQLiteModel {
    
    func insertOrUpdate() {
        objc_sync_enter(self)
        try! model.insertOrUpdate()
        dispatch_async(dispatch_get_main_queue()) {
            self.property.value = self.model
        }
        objc_sync_exit(self)
    }
    
    func insertOrUpdate(closure: ModelBox -> ()) {
        objc_sync_enter(self)
        closure(self)
        try! model.insertOrUpdate()
        dispatch_async(dispatch_get_main_queue()) {
            self.property.value = self.model
        }
        objc_sync_exit(self)
    }
    
}

class Models {
    
    static var optographs = ModelCache<Optograph>()
    static var persons = ModelCache<Person>()
    static var locations = ModelCache<Location>()
    
}

protocol ModelCacheType: class {
    typealias ModelType: Model
    
    var cache: [UUID: ModelBox<ModelType>] { get set }
}

extension ModelCacheType {
    
    func create(model: ModelType) -> ModelBox<ModelType> {
        assert(cache[model.ID] == nil)
        cache[model.ID] = ModelBox(model: model)
        return cache[model.ID]!
    }
    
    func touch(model: ModelType?) -> ModelBox<ModelType>? {
        if let model = model {
            return touch(model)
        }
        return nil
    }
    
    func touch(model: ModelType) -> ModelBox<ModelType> {
        guard let box = cache[model.ID] else {
            return create(model)
        }
        
        if model.updatedAt > box.model.updatedAt {
            box.replace(model)
        }
        
        return box
    }
    
    func forget(uuid: UUID?) {
        if let uuid = uuid {
            cache.removeValueForKey(uuid)
        }
    }
    
    subscript(uuid: UUID?) -> ModelBox<ModelType>? {
        get {
            guard let uuid = uuid else {
                return nil
            }
            return cache[uuid]
        }
    }
    
}

extension ModelCacheType where ModelType: MergeApiModel {
    
    func touch(apiModel: ApiModel) -> ModelBox<ModelType> {
        let apiModel = apiModel as! ModelType.AM
        
        if let box = cache[apiModel.ID]  {
            if apiModel.updatedAt > box.model.updatedAt {
                box.model.mergeApiModel(apiModel)
            }
            return box
        }
        
        var model = ModelType.newInstance()
        model.mergeApiModel(apiModel)
        
        return create(model)
    }
    
    func touch(apiModel: ApiModel?) -> ModelBox<ModelType>? {
        if let apiModel = apiModel {
            return touch(apiModel)
        }
        return nil
    }
    
}

class ModelCache<M: Model>: ModelCacheType {
    typealias ModelType = M
    
    var cache: [UUID: ModelBox<ModelType>] = [:]
}
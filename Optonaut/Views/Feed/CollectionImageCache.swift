//
//  CollectionImageCache.swift
//  Optonaut
//
//  Created by Johannes Schickling on 11/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import Kingfisher
import SpriteKit
import Async

func ==(lhs: CubeImageCache.Index, rhs: CubeImageCache.Index) -> Bool {
    return lhs.face == rhs.face
        && lhs.x == rhs.x
        && lhs.y == rhs.y
        && lhs.d == rhs.d
}

class CubeImageCache {
    
    struct Index: Hashable {
        let face: Int
        let x: Float
        let y: Float
        let d: Float
        
        var hashValue: Int {
            return face + Int(100 * x) + Int(10000 * y) + Int(1000000 * d)
        }
    }
    
    typealias Callback = (SKTexture, index: Index) -> Void
    private typealias InnerItem = (image: SKTexture?, downloadTask: RetrieveImageTask?)
    
    private var items: [Index: InnerItem] = [:]
    private let optographID: UUID
    private let side: TextureSide
    
    init(optographID: UUID, side: TextureSide) {
        self.optographID = optographID
        self.side = side
    }
    
    deinit {
        logRetain()
    }
    
    func get(index: Index, callback: Callback) {
        
        if let item = items[index] {
            if let image = item.image {
                callback(image, index: index)
            }
        } else {
            let textureSize = getTextureWidth(UIScreen.mainScreen().bounds.width, hfov: HorizontalFieldOfView)
            print(textureSize)
            let downloadTask = KingfisherManager.sharedManager.retrieveImageWithURL(
                NSURL(string: TextureURL(optographID, side: side, size: Int(textureSize), face: index.face, x: index.x, y: index.y, d: index.d))!,
//                NSURL(string: ImageURL(optographs[index].leftTextureAssetID, width: Int(getTextureWidth(HorizontalFieldOfView) / Float(UIScreen.mainScreen().scale))))!,
                optionsInfo: nil,
//                optionsInfo: [.Options(.LowPriority)],
                progressBlock: nil,
                completionHandler: { [weak self] (image, error, _, _) in
                    Async.userInteractive {
                        if let image = image where self?.items[index] != nil {
                            let tex = SKTexture(image: image)
                            self?.items[index]?.image = tex
                            self?.items[index]?.downloadTask = nil
                            callback(tex, index: index)
                        }
                    }
                }
            )
            
            items[index] = (image: nil, downloadTask: downloadTask)
        }
    }
    
    func dispose() {
        items.values.forEach { $0.downloadTask?.cancel() }
    }
    
}

class CollectionImageCache {
    
    private typealias Item = (index: Int, innerCache: CubeImageCache)
    
    private static let cacheSize = 5
    
    private var items: [Item?]
//    private var activeIndex = 0
    private let debouncerGet: Debouncer
    private let debouncerTouch: Debouncer
    
    init() {
        items = [Item?](count: CollectionImageCache.cacheSize, repeatedValue: nil)
        
        let queue = dispatch_queue_create("collection_image_cache", DISPATCH_QUEUE_SERIAL)
        debouncerGet = Debouncer(queue: queue, delay: 0.1)
        debouncerTouch = Debouncer(queue: queue, delay: 0.1)
    }
    
    func get(index: Int, optographID: UUID, side: TextureSide, cubeIndices: [CubeImageCache.Index], callback: CubeImageCache.Callback) {
        
        let cacheIndex = index % CollectionImageCache.cacheSize
        
        if let item = items[cacheIndex] where item.index == index {
            for cubeIndex in cubeIndices {
                item.innerCache.get(cubeIndex, callback: callback)
            }
        } else {
            // debounce in order to avoid download/cancel when scrolling fast
            debouncerGet.debounce { [weak self] in
                self?.items[cacheIndex]?.innerCache.dispose()
                self?.items[cacheIndex] = (index: index, innerCache: CubeImageCache(optographID: optographID, side: side))
                self?.get(index, optographID: optographID, side: side, cubeIndices: cubeIndices, callback: callback)
            }
        }
        
    }
    
//    func touch(activeIndex: Int) {
//        self.activeIndex = activeIndex
//        
//        let startIndex = max(0, activeIndex - 2)
//        let endIndex = min(optographs.count - 1, activeIndex + 2)
//        
//        for index in startIndex...endIndex {
//            update(index, callback: nil)
//        }
//    }
    
    func reset() {
        items.forEach { $0?.innerCache.dispose() }
        items = [Item?](count: CollectionImageCache.cacheSize, repeatedValue: nil)
    }
    
    func delete(indices: [Int]) {
        var count = 0
        for index in indices {
            let shiftedIndex = index - count
            if let item = items.filter({ $0?.index == shiftedIndex }).first! {
                item.innerCache.dispose()
                
                // shift remaining items down
                let shiftLimit = CollectionImageCache.cacheSize - count - 1 // 1 because one gets deleted anyways
                if shiftLimit >= 1 {
                    for shift in 0..<shiftLimit {
                        items[(shiftedIndex + shift) % CollectionImageCache.cacheSize] = items[(shiftedIndex + shift + 1) % CollectionImageCache.cacheSize]
                        items[(shiftedIndex + shift) % CollectionImageCache.cacheSize]?.index--
                    }
                    items[(shiftedIndex + shiftLimit) % CollectionImageCache.cacheSize] = nil
                }
                count++
            }
        }
    }
    
    func insert(indices: [Int]) {
        for index in indices {
            let sortedCacheIndices = items.flatMap({ $0?.index }).sort { $0.0 < $0.1 }
            guard let minIndex = sortedCacheIndices.first, maxIndex = sortedCacheIndices.last else {
                continue
            }
            
            if index > maxIndex {
                continue
            }
            
            // shift items "up" with item.index >= index
            let lowerShiftIndexOffset = max(0, index - minIndex)
            for shiftIndexOffset in (lowerShiftIndexOffset..<CollectionImageCache.cacheSize - 1).reverse() {
                items[(minIndex + shiftIndexOffset + 1) % CollectionImageCache.cacheSize] = items[(minIndex + shiftIndexOffset) % CollectionImageCache.cacheSize]
                items[(minIndex + shiftIndexOffset + 1) % CollectionImageCache.cacheSize]?.index++
            }
            
            items[(minIndex + lowerShiftIndexOffset) % CollectionImageCache.cacheSize] = nil
//            update(minIndex + lowerShiftIndexOffset, callback: nil)
        }
    }
}

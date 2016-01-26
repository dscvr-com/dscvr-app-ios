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
//    private typealias InnerItem = (image: SKTexture?, downloadTask: RetrieveImageTask?)
    private class Item {
        var image: SKTexture?
        var downloadTask: RetrieveImageTask?
        var callback: Callback?
    }
    
    private let queue = dispatch_queue_create("collection_image_cube_cache", DISPATCH_QUEUE_CONCURRENT)
    
    private var items: [Index: Item] = [:]
    private let optographID: UUID
    private let side: TextureSide
    private var textureSize: CGFloat
    
    init(optographID: UUID, side: TextureSide, textureSize: CGFloat) {
        self.optographID = optographID
        self.side = side
        self.textureSize = textureSize
    }
    
    deinit {
        dispose()
        logRetain()
    }
    
    func updateTextureSize(textureSize: CGFloat) {
        self.textureSize = textureSize
        dispose()
    }
    
    func get(index: Index, callback: Callback?) {
        
        if let image = items[index]?.image {
            callback?(image, index: index)
        } else if items[index]?.downloadTask == nil {
            // Image is resolved by URL - query whole face and then get subface manually.
            // Occurs when image was just taken on this phone
            let queryIndex = Index(face: index.face, x: 0.0, y: 0.0, d: 1.0)
            if let image = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url(queryIndex, textureSize: 0)) {
                let resizedImage = image.subface(CGFloat(index.x), y: CGFloat(index.y), w: CGFloat(index.d), d: Int(textureSize * CGFloat(index.d)))
                let tex = SKTexture(image: resizedImage)
                
                callback?(tex, index: index)
                
                let item = Item()
                item.image = tex
                
                sync(self) {
                    self.items[index] = item
                }
                
            } else {
                let item = Item()
                item.callback = callback
                
                sync(self) {
                    self.items[index] = item
                    
                    item.downloadTask = KingfisherManager.sharedManager.retrieveImageWithURL(
                        NSURL(string: self.url(index, textureSize: self.textureSize))!,
                        optionsInfo: nil,
                        progressBlock: nil,
                        completionHandler: { (image, error, _, _) in
                            if let error = error where error.code != -999 {
                                print(error)
                            }
                            // needed because completionHandler is called on mainthread
                            dispatch_async(self.queue) {
                                sync(self) {
                                    if let image = image, item = self.items[index] {
                                        let tex = SKTexture(image: image)
                                        item.image = tex
                                        item.downloadTask = nil
                                        item.callback?(tex, index: index)
                                    }
                                }
                            }
                        }
                    )
                    
                }
                
            }
        }
    }
    
    func forget(index: Index) {
        sync(self) {
            self.items[index]?.downloadTask?.cancel()
            self.items.removeValueForKey(index)
        }
    }
    
    func disable() {
        sync(self) {
            self.items.values.forEach { $0.callback = nil }
        }
    }
    
    private func dispose() {
        sync(self) {
            self.items.values.forEach { $0.downloadTask?.cancel() }
            self.items.removeAll()
        }
    }
    
    private func url(index: Index, textureSize: CGFloat) -> String {
        return TextureURL(optographID, side: side, size: Int(Float(textureSize) * index.d), face: index.face, x: index.x, y: index.y, d: index.d)
    }
    
}

class CollectionImageCache {
    
    private typealias Item = (index: Int, innerCache: CubeImageCache)
    
    private static let cacheSize = 5
    
    private var items: [Item?]
    private let debouncerTouch: Debouncer
    
    private let textureSize: CGFloat
    
    init(textureSize: CGFloat) {
        self.textureSize = textureSize
        
        items = [Item?](count: CollectionImageCache.cacheSize, repeatedValue: nil)
        
        debouncerTouch = Debouncer(queue: dispatch_get_main_queue(), delay: 0.1)
    }
    
    func get(index: Int, optographID: UUID, side: TextureSide) -> CubeImageCache {
        assertMainThread()
        
        let cacheIndex = index % CollectionImageCache.cacheSize
        
        if let item = items[cacheIndex] where item.index == index {
            return item.innerCache
        } else {
            let item = (index: index, innerCache: CubeImageCache(optographID: optographID, side: side, textureSize: textureSize))
            items[cacheIndex] = item
            return item.innerCache
        }
    }
    
    func disable(index: Int) {
        assertMainThread()
        
        items[index % CollectionImageCache.cacheSize]?.innerCache.disable()
    }
    
    func touch(index: Int, optographID: UUID, side: TextureSide, cubeIndices: [CubeImageCache.Index]) {
        assertMainThread()
        
        let cacheIndex = index % CollectionImageCache.cacheSize
        let textureSize = self.textureSize
        
        if items[cacheIndex] == nil || items[cacheIndex]?.index != index {
            debouncerTouch.debounce {
                let item = (index: index, innerCache: CubeImageCache(optographID: optographID, side: side, textureSize: textureSize))
                self.items[cacheIndex] = item
                for cubeIndex in cubeIndices {
                    item.innerCache.get(cubeIndex, callback: nil)
                }
            }
        }
    }
    
    func reset() {
        assertMainThread()
        
        items = [Item?](count: CollectionImageCache.cacheSize, repeatedValue: nil)
    }
    
    func delete(indices: [Int]) {
        assertMainThread()
        
        var count = 0
        for index in indices {
            let shiftedIndex = index - count
            if items.contains({ $0?.index == shiftedIndex }) {
                
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
        assertMainThread()
        
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
        }
    }
}

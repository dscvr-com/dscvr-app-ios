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
    private class InnerItem {
        var image: SKTexture?
        var downloadTask: RetrieveImageTask?
    }
    
    private let queue = dispatch_queue_create("collection_image_cube_cache", DISPATCH_QUEUE_CONCURRENT)
    
    private var items: [Index: InnerItem] = [:]
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
            if let image = KingfisherManager.sharedManager.cache.retrieveImageInDiskCacheForKey(url(index, textureSize: 0)) {
//                TODO check if async is needed here
//                dispatch_async(queue) {
                    let resizedImage = image.resized(.Width, value: textureSize)
                    let tex = SKTexture(image: resizedImage)
//                    items[index]?.image = tex
//                    items[index]?.downloadTask = nil
                    callback?(tex, index: index)
//                }
                
//                dispatch_async(queue) { [weak self] in
                    let item = InnerItem()
                    item.image = tex
                    items[index] = item
//                }
            } else {
                let downloadTask = KingfisherManager.sharedManager.retrieveImageWithURL(
                    NSURL(string: url(index, textureSize: textureSize))!,
                    //                NSURL(string: ImageURL(optographs[index].leftTextureAssetID, width: Int(getTextureWidth(HorizontalFieldOfView) / Float(UIScreen.mainScreen().scale))))!,
                    optionsInfo: nil,
                    //                optionsInfo: [.Options(.LowPriority)],
                    progressBlock: nil,
                    completionHandler: { [weak self] (image, error, _, _) in
                        if let strongSelf = self {
                            if let error = error where error.code != -999 {
                                print(error)
                            }
                            dispatch_async(strongSelf.queue) {
                                if let image = image where strongSelf.items[index] != nil {
                                    let tex = SKTexture(image: image)
                                    strongSelf.items[index]?.image = tex
                                    strongSelf.items[index]?.downloadTask = nil
                                    callback?(tex, index: index)
                                }
                            }
                        }
                    }
                )
                
//                dispatch_async(queue) { [weak self] in
                let item = InnerItem()
                item.downloadTask = downloadTask
                items[index] = item
//                }
            }
        }
    }
    
    func forget(index: Index) {
//        dispatch_async(queue) { [weak self] in
            items[index]?.downloadTask?.cancel()
//            self?.items[index] = nil
            items.removeValueForKey(index)
//        }
    }
    
    private func dispose() {
        items.values.forEach { $0.downloadTask?.cancel() }
        items.removeAll()
    }
    
    private func url(index: Index, textureSize: CGFloat) -> String {
        return TextureURL(optographID, side: side, size: Int(Float(textureSize) * index.d), face: index.face, x: index.x, y: index.y, d: index.d)
    }
    
}

class CollectionImageCache {
    
    private typealias Item = (index: Int, innerCache: CubeImageCache)
    
    private static let cacheSize = 5
    
    private var items: [Item?]
//    private var activeIndex = 0
    private let debouncerGet: Debouncer
    private let debouncerTouch: Debouncer
    
    private let textureSize: CGFloat
    
    init(textureSize: CGFloat) {
        self.textureSize = textureSize
        
        items = [Item?](count: CollectionImageCache.cacheSize, repeatedValue: nil)
        
        let queue = dispatch_queue_create("collection_image_cache", DISPATCH_QUEUE_SERIAL)
        debouncerGet = Debouncer(queue: queue, delay: 0.1)
        debouncerTouch = Debouncer(queue: queue, delay: 0.1)
    }
    
    func get(index: Int, optographID: UUID, side: TextureSide) -> CubeImageCache {
        let cacheIndex = index % CollectionImageCache.cacheSize
        
        if let item = items[cacheIndex] where item.index == index {
            return item.innerCache
        } else {
            let item = (index: index, innerCache: CubeImageCache(optographID: optographID, side: side, textureSize: textureSize))
            items[cacheIndex] = item
            return item.innerCache
        }
    }
    
    func touch(index: Int, optographID: UUID, side: TextureSide, cubeIndices: [CubeImageCache.Index]) {
        let cacheIndex = index % CollectionImageCache.cacheSize
        let textureSize = self.textureSize
        
        if items[cacheIndex] == nil || items[cacheIndex]?.index != index {
            debouncerTouch.debounce { [weak self] in
                let item = (index: index, innerCache: CubeImageCache(optographID: optographID, side: side, textureSize: textureSize))
                self?.items[cacheIndex] = item
                for cubeIndex in cubeIndices {
                    item.innerCache.get(cubeIndex, callback: nil)
                }
            }
        }
    }
    
    func reset() {
        items = [Item?](count: CollectionImageCache.cacheSize, repeatedValue: nil)
    }
    
    func delete(indices: [Int]) {
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

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
    
    enum MemoryPolicy {
        case Aggressive // Agressive memory policy - dispose images as soon as they are no longer needed
        case Elastic // Elastic memory policy - keep images in memory cache until memory warnings are received
    }
    
    typealias Callback = (SKTexture, index: Index) -> Void
    
    private class Item {
        var image: SKTexture?
        var downloadTask: ImageManager.DownloadTask?
        var callback: Callback?
        var canDelete: Bool = false
    }
    
    private let queue = dispatch_queue_create("collection_image_cube_cache", DISPATCH_QUEUE_CONCURRENT)
    private let memoryPolicy: MemoryPolicy
    private var items: [Index: Item] = [:]
    let optographID: UUID
    private let side: TextureSide
    private var textureSize: CGFloat
    private var disposed: Bool = false
    
    convenience init(optographID: UUID, side: TextureSide, textureSize: CGFloat) {
        self.init(optographID: optographID, side: side, textureSize: textureSize, memoryPolicy: .Aggressive)
    }
    
    init(optographID: UUID, side: TextureSide, textureSize: CGFloat, memoryPolicy: MemoryPolicy) {
        self.optographID = optographID
        self.side = side
        self.textureSize = textureSize
        self.memoryPolicy = memoryPolicy
    }
    
    deinit {
        dispose()
        logRetain()
    }
    
    func updateTextureSize(textureSize: CGFloat) {
        self.textureSize = textureSize
        dispose()
    }
    
    private func fullfillImageCallback(index: CubeImageCache.Index, callback: Callback?, image: UIImage) {
        let tex = SKTexture(image: image)
        
        callback?(tex, index: index)
        
        let item = Item()
        item.image = tex
        
        self.items[index] = item
        
        return;
    }
    
    func get(index: Index, callback: Callback?) {
        sync(self) {
            if self.disposed {
                print("Warning: Called get on a disposed Image Cache")
                return
            }
            if let image = self.items[index]?.image {
                // Case 1 - Image is Pre-Fetched.
                callback?(image, index: index)
            } else if self.items[index]?.downloadTask == nil {
                // Case 2.1 - Image is not Pre-Fetched, but we have it in our disk cache.
                let tiledUrl =  NSURL(string: self.url(index, textureSize: self.textureSize))!
                print("imageUrl>>>>>>>",tiledUrl)
                let tiledImage = ImageManager.sharedInstance.retrieveImageFromCache(tiledUrl, requester: self)
                
                if let tiledImage = tiledImage {
                    self.fullfillImageCallback(index, callback: callback, image: tiledImage)
                    return
                }
                
                // Case 2.2 - Image is not Pre-Fetched, but we have the full face in our disk cache.
                
                // Image is resolved by URL - query whole face and then get subface manually.
                // Occurs when image was just taken on this phone
                let fullFaceUrl = NSURL(string: self.url(Index(face: index.face, x: 0.0, y: 0.0, d: 1.0), textureSize: 0))!
                let originalImage = ImageManager.sharedInstance.retrieveImageFromCache(fullFaceUrl, requester: self)
                
                
                if let originalImage = originalImage {
                    
                    let subfaceSize = index.d
                    let subfaceCount = Int(Float(1) / subfaceSize + Float(0.5))
                   
                    // If we request a subface in this case, let's cheat and prepare all subfaces at once.
                    for x in 0..<subfaceCount {
                        for y in 0..<subfaceCount {
                            let tiledIndex = Index(face: index.face, x: Float(x) * subfaceSize, y: Float(y) * subfaceSize, d: subfaceSize)
                            let tiledImage = originalImage.subface(CGFloat(tiledIndex.x), y: CGFloat(tiledIndex.y), w: CGFloat(tiledIndex.d), d: Int(self.textureSize))
                            
                            // Store subface - way faster loading next time.
                            let tiledUrl = NSURL(string: self.url(tiledIndex, textureSize: self.textureSize))!
                            ImageManager.sharedInstance.addImageToCache(tiledUrl, image: tiledImage)
                            self.fullfillImageCallback(tiledIndex, callback: nil, image: tiledImage)
                        }
                    }
                    callback?(self.items[index]!.image!, index: index)
                    return;
                }
                
                // Case 2.3 - We don't have anything. Download.
                let item = Item()
                item.callback = callback
                self.items[index] = item
            
                item.downloadTask = ImageManager.sharedInstance.downloadImage(
                    tiledUrl, requester: self,
                    completionHandler: { (image, error, _, _) in
                        if let error = error where error.code != -999 {
                            print(error)
                        }
                        // needed because completionHandler is called on mainthread
                        dispatch_async(self.queue) {
                            sync(self) {
                                if let image = image, item = self.items[index] {
                                    let tex = SKTexture(image: image)
                                    
                                    item.downloadTask = nil
                                    
                                    if item.callback != nil {
                                        item.image = tex
                                        item.callback?(tex, index: index)
                                        item.callback = nil
                                    } else {
                                        self.forgetInternal(index)
                                    }
                                }
                            }
                        }
                    }
                )
    
            } else if self.items[index]?.callback == nil {
                self.items[index]?.callback = callback
            }
        }
    }
    
    private func forgetInternal(index: Index) {
        // This method needs to be called inside sync
        switch memoryPolicy {
        case .Aggressive:
            self.items.removeValueForKey(index)
            break
        case .Elastic:
            if let item = self.items[index] {
                item.callback = nil
                item.canDelete = true
            }
            break
        }
    }
    
    func forget(index: Index) {
        sync(self) {
            self.items[index]?.downloadTask?.cancel()
            self.forgetInternal(index)
        }
    }
    
    /*
    * Disables all callbacks without freeing the memory.
    */
    func disable() {
        sync(self) {
            self.items.values.forEach { $0.callback = nil }
        }
    }
    
    /*
    * Removes all images from in-memory cache if they are not currently in use.
    */
    func onMemoryWarning() {
        sync(self) {
            for (index, value) in self.items {
                if value.canDelete {
                    self.items.removeValueForKey(index)
                }
            }
        }
    }
    
    /*
    * Disables all callbacks and frees all memory.
    */
    func dispose() {
        sync(self) {
            self.items.values.forEach {
                $0.downloadTask?.cancel()
                $0.callback = nil
            }
            self.disposed = true
            self.items.removeAll()
        }
    }
    
    private func url(index: Index, textureSize: CGFloat) -> String {
        return TextureURL(optographID, side: side, size: textureSize * CGFloat(index.d), face: index.face, x: index.x, y: index.y, d: index.d)
    }
    
}

class CollectionImageCache {
    
    private typealias Item = (index: Int, innerCache: CubeImageCache)
    
    private static let cacheSize = 5
    
    private var items: [Item?]
    private let debouncerTouch: Debouncer
    
    private let textureSize: CGFloat
    private let logsPath:NSURL?
    private let fileManager = NSFileManager.defaultManager()
    
    init(textureSize: CGFloat) {
        self.textureSize = textureSize
        
        items = [Item?](count: CollectionImageCache.cacheSize, repeatedValue: nil)
        
        debouncerTouch = Debouncer(queue: dispatch_get_main_queue(), delay: 0.1)
        
        let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0])
        logsPath = documentsPath.URLByAppendingPathComponent("mp4s")
        
        do {
            try fileManager.createDirectoryAtPath(logsPath!.path!, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
    }
    
    deinit {
        logRetain()
    }
    
    func get(index: Int, optographID: UUID, side: TextureSide) -> CubeImageCache {
        assertMainThread()
        
        let cacheIndex = index % CollectionImageCache.cacheSize
        
        if let item = items[cacheIndex] where item.index == index {
            assert(item.innerCache.optographID == optographID)
            return item.innerCache
        } else {
            let item = (index: index, innerCache: CubeImageCache(optographID: optographID, side: side, textureSize: textureSize))
            items[cacheIndex]?.innerCache.dispose()
            items[cacheIndex] = item
            return item.innerCache
        }
    }
    func insertMp4IntoCache(url:String,optographId:String) -> String{
        
        let priority = DISPATCH_QUEUE_PRIORITY_BACKGROUND
        
        let path = self.logsPath!.path!.stringByAppendingPathComponent("\(optographId).mp4")
        
        if !self.fileManager.fileExistsAtPath(path) {
            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                
                let videoData = NSData(contentsOfURL: NSURL(string:url)!)
                
                if (videoData != nil) {
                    
                    videoData?.writeToFile(path, atomically: true)
                }
            }
            return ""
        } else {
            return path
        }
    }
    
    func deleteMp4(optographId:String) -> Bool {
        let path = self.logsPath!.path!.stringByAppendingPathComponent("\(optographId).mp4")
        
        do{
            try fileManager.removeItemAtPath(path)
            return true
        }catch {
            return false
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
    
    func resetExcept(index: Int) {
        for i in 0..<CollectionImageCache.cacheSize where i != (index % CollectionImageCache.cacheSize) {
            items[i]?.innerCache.dispose()
            items[i] = nil
        }
    }
    
    func reset() {
        assertMainThread()
        
        for item in items {
            item?.innerCache.dispose() // Forcibly dispose internal data structures.
        }
        
        items = [Item?](count: CollectionImageCache.cacheSize, repeatedValue: nil)
    }
    
    func onMemoryWarning() {
        for item in items {
            item?.innerCache.onMemoryWarning()
        }
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
                        items[(shiftedIndex + shift) % CollectionImageCache.cacheSize]?.index -= 1
                    }
                    items[(shiftedIndex + shiftLimit) % CollectionImageCache.cacheSize] = nil
                }
                count += 1
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
                items[(minIndex + shiftIndexOffset + 1) % CollectionImageCache.cacheSize]?.index+=1
            }
            
            items[(minIndex + lowerShiftIndexOffset) % CollectionImageCache.cacheSize] = nil
        }
    }
}

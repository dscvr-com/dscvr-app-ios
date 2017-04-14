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
        case aggressive // Agressive memory policy - dispose images as soon as they are no longer needed
        case elastic // Elastic memory policy - keep images in memory cache until memory warnings are received
    }
    
    typealias Callback = (SKTexture, _ index: Index) -> Void
    
    fileprivate class Item {
        var image: SKTexture?
        var downloadTask: ImageManager.DownloadTask?
        var callback: Callback?
        var canDelete: Bool = false
    }
    
    fileprivate let queue = DispatchQueue(label: "collection_image_cube_cache", attributes: DispatchQueue.Attributes.concurrent)
    fileprivate let memoryPolicy: MemoryPolicy
    fileprivate var items: [Index: Item] = [:]
    let optographID: UUID
    fileprivate let side: TextureSide
    fileprivate var textureSize: CGFloat
    fileprivate var disposed: Bool = false
    
    convenience init(optographID: UUID, side: TextureSide, textureSize: CGFloat) {
        self.init(optographID: optographID, side: side, textureSize: textureSize, memoryPolicy: .aggressive)
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
    
    func updateTextureSize(_ textureSize: CGFloat) {
        self.textureSize = textureSize
        dispose()
    }
    
    fileprivate func fullfillImageCallback(_ index: CubeImageCache.Index, callback: Callback?, image: UIImage) {
        let tex = SKTexture(image: image)
        
        callback?(tex, index)
        
        let item = Item()
        item.image = tex
        
        self.items[index] = item
        
        return;
    }
    
    func get(_ index: Index, callback: Callback?) {
        sync(self) {
            if self.disposed {
                print("Warning: Called get on a disposed Image Cache")
                return
            }
            if let image = self.items[index]?.image {
                // Case 1 - Image is Pre-Fetched.
                callback?(image, index)
            } else if self.items[index]?.downloadTask == nil {
                // Case 2.1 - Image is not Pre-Fetched, but we have it in our disk cache.
                let tiledUrl =  URL(string: self.url(index, textureSize: self.textureSize))!
                let tiledImage = ImageManager.sharedInstance.retrieveImageFromCache(tiledUrl, requester: self)
                
                if let tiledImage = tiledImage {
                    self.fullfillImageCallback(index, callback: callback, image: tiledImage)
                    return
                }
                
                // Case 2.2 - Image is not Pre-Fetched, but we have the full face in our disk cache.
                
                // Image is resolved by URL - query whole face and then get subface manually.
                // Occurs when image was just taken on this phone
                let fullFaceUrl = URL(string: self.url(Index(face: index.face, x: 0.0, y: 0.0, d: 1.0), textureSize: 0))!
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
                            let tiledUrl = URL(string: self.url(tiledIndex, textureSize: self.textureSize))!
                            ImageManager.sharedInstance.addImageToCache(tiledUrl, image: tiledImage)
                            self.fullfillImageCallback(tiledIndex, callback: nil, image: tiledImage)
                        }
                    }
                    callback?(self.items[index]!.image!, index)
                    return;
                }
                
                // Case 2.3 - We don't have anything. Download.
                let item = Item()
                item.callback = callback
                self.items[index] = item
            
                item.downloadTask = ImageManager.sharedInstance.downloadImage(
                    tiledUrl, requester: self,
                    completionHandler: { (image, error, _, _) in
                        if let error = error, error.code != -999 {
                            print(error)
                        }
                        // needed because completionHandler is called on mainthread
                        self.queue.async() {
                            sync(self) {
                                if let image = image, let item = self.items[index] {
                                    let tex = SKTexture(image: image)
                                    
                                    item.downloadTask = nil
                                    
                                    if item.callback != nil {
                                        item.image = tex
                                        item.callback?(tex, index)
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
    
    fileprivate func forgetInternal(_ index: Index) {
        // This method needs to be called inside sync
        switch memoryPolicy {
        case .aggressive:
            self.items.removeValue(forKey: index)
            break
        case .elastic:
            if let item = self.items[index] {
                item.callback = nil
                item.canDelete = true
            }
            break
        }
    }
    
    func forget(_ index: Index) {
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
                    self.items.removeValue(forKey: index)
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
    
    fileprivate func url(_ index: Index, textureSize: CGFloat) -> String {
        return TextureURL(optographID, side: side, size: textureSize * CGFloat(index.d), face: index.face, x: index.x, y: index.y, d: index.d)
    }
    
}

class CollectionImageCache {
    
    fileprivate typealias Item = (index: Int, innerCache: CubeImageCache)
    
    fileprivate static let cacheSize = 5
    
    fileprivate var items: [Item?]
    fileprivate let debouncerTouch: Debouncer
    
    fileprivate let textureSize: CGFloat
    fileprivate let logsPath:URL?
    fileprivate let fileManager = FileManager.default
    
    init(textureSize: CGFloat) {
        self.textureSize = textureSize
        
        items = [Item?](repeating: nil, count: CollectionImageCache.cacheSize)
        
        debouncerTouch = Debouncer(queue: DispatchQueue.main, delay: 0.1)
        
        let documentsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        logsPath = documentsPath.appendingPathComponent("StoryFiles")
        
        do {
            try fileManager.createDirectory(atPath: logsPath!.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
    }
    
    deinit {
        logRetain()
    }
    
    func get(_ index: Int, optographID: UUID, side: TextureSide) -> CubeImageCache {
        assertMainThread()
        
        let cacheIndex = index % CollectionImageCache.cacheSize
        
        if let item = items[cacheIndex], item.index == index {
            assert(item.innerCache.optographID == optographID)
            return item.innerCache
        } else {
            let item = (index: index, innerCache: CubeImageCache(optographID: optographID, side: side, textureSize: textureSize))
            items[cacheIndex]?.innerCache.dispose()
            items[cacheIndex] = item
            return item.innerCache
        }
    }
    
    func getStory( _ optographID: UUID, side: TextureSide) -> CubeImageCache {
        assertMainThread()
        
        
        let item = (index: index, innerCache: CubeImageCache(optographID: optographID, side: side, textureSize: textureSize))
        return item.innerCache
        
    }
    
    func insertMp4IntoCache(_ url:String,optographId:String) -> String{
        
        let priority = DispatchQueue.GlobalQueuePriority.background
        
        let path = self.logsPath!.path.stringByAppendingPathComponent("\(optographId).mp4")
        
        if !self.fileManager.fileExists(atPath: path) {
            DispatchQueue.global(priority: priority).async {
                
                let videoData = try? Data(contentsOf: URL(string:url)!)
                
                if (videoData != nil) {
                    
                    try? videoData?.write(to: URL(fileURLWithPath: path), options: [.atomic])
                }
            }
            return ""
        } else {
            return path
        }
    }
    
    func deleteMp4(_ optographId:String) -> Bool {
        let path = self.logsPath!.path.stringByAppendingPathComponent("\(optographId).mp4")
        
        do{
            try fileManager.removeItem(atPath: path)
            return true
        }catch {
            return false
        }
    }
    
    func insertStoryFile(_ url:URL?,file:Data?,fileName:String) -> String{
        
        let priority = DispatchQueue.GlobalQueuePriority.background
        
        let path = self.logsPath!.path.stringByAppendingPathComponent("\(fileName)")
        
        if !self.fileManager.fileExists(atPath: path) {
            DispatchQueue.global(priority: priority).async {
                if url != nil {
                    let videoData = try? Data(contentsOf: url!)
                    if (videoData != nil) {
                        try? videoData?.write(to: URL(fileURLWithPath: path), options: [.atomic])
                    }
                } else {
                    if let videoData:Data = file {
                        try? videoData.write(to: URL(fileURLWithPath: path), options: [.atomic])
                    }
                }
            }
            return ""
        } else {
            return path
        }
    }
    
    func deleteStoryFile(_ fileName:String) -> Bool {
        let path = self.logsPath!.path.stringByAppendingPathComponent("\(fileName)")
        
        do{
            try fileManager.removeItem(atPath: path)
            return true
        }catch {
            return false
        }
    }
    
    
    func getOptocache(_ index: Int, optographID: UUID, side: TextureSide) -> CubeImageCache {
        assertMainThread()
        
        let cacheIndex = index % CollectionImageCache.cacheSize
        
            let item = (index: index, innerCache: CubeImageCache(optographID: optographID, side: side, textureSize: textureSize))
            items[cacheIndex]?.innerCache.dispose()
            items[cacheIndex] = item
            return item.innerCache
        
    }
    
    func disable(_ index: Int) {
        assertMainThread()
        
        items[index % CollectionImageCache.cacheSize]?.innerCache.disable()
    }
    
    func touch(_ index: Int, optographID: UUID, side: TextureSide, cubeIndices: [CubeImageCache.Index]) {
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
    
    func resetExcept(_ index: Int) {
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
        
        items = [Item?](repeating: nil, count: CollectionImageCache.cacheSize)
    }
    
    func onMemoryWarning() {
        for item in items {
            item?.innerCache.onMemoryWarning()
        }
    }
    
    func delete(_ indices: [Int]) {
        assertMainThread()
        
        var count = 0
        for index in indices {
            let shiftedIndex = index - count
            if items.contains(where: { $0?.index == shiftedIndex }) {
                
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
    
    func insert(_ indices: [Int]) {
        assertMainThread()
        
        for index in indices {
            let sortedCacheIndices = items.flatMap({ $0?.index }).sorted { $0.0 < $0.1 }
            guard let minIndex = sortedCacheIndices.first, let maxIndex = sortedCacheIndices.last else {
                continue
            }
            
            if index > maxIndex {
                continue
            }
            
            // shift items "up" with item.index >= index
            let lowerShiftIndexOffset = max(0, index - minIndex)
            for shiftIndexOffset in (lowerShiftIndexOffset..<CollectionImageCache.cacheSize - 1).reversed() {
                items[(minIndex + shiftIndexOffset + 1) % CollectionImageCache.cacheSize] = items[(minIndex + shiftIndexOffset) % CollectionImageCache.cacheSize]
                items[(minIndex + shiftIndexOffset + 1) % CollectionImageCache.cacheSize]?.index+=1
            }
            
            items[(minIndex + lowerShiftIndexOffset) % CollectionImageCache.cacheSize] = nil
        }
    }
}

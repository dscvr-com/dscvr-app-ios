//
//  ImageCacheService.swift
//  Optonaut
//
//  Created by Emi on 30/01/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import Kingfisher

class ImageManager {
    
    class DownloadTask {
        let url: URL
        let requester: AnyObject
        let syncRoot: AnyObject
        let completionHandler: CompletionHandler
        var internalTask: RetrieveImageTask?
        var cancelled = false
        
        init(URL: Foundation.URL, requester: AnyObject, syncRoot: AnyObject, completionHandler: @escaping CompletionHandler) {
            self.url = URL
            self.requester = requester
            self.completionHandler = completionHandler
            self.cancelled = false
            self.syncRoot = syncRoot
        }
        
        func cancel() {
            sync(syncRoot) {
                self.cancelled = true
                self.internalTask?.cancel()
            }
        }
    }
    
    typealias CompletionHandler = ((_ image: UIImage?, _ error: NSError?, _ cacheType: CacheType, _ imageURL: NSURL?) -> ())

    static let sharedInstance = ImageManager(manager: KingfisherManager.shared)
    
    fileprivate let manager: KingfisherManager
    fileprivate var downloadQueue: [DownloadTask]
    fileprivate var currentDownloads: Int
    fileprivate let maxConcurrentDownloads: Int
    fileprivate let queueLock: AnyObject
    
    fileprivate var lastRequester: AnyObject?
    
    init(manager: KingfisherManager) {
        self.manager = manager
        self.downloadQueue = [DownloadTask]()
        self.queueLock = NSObject()
        self.currentDownloads = 0
        self.maxConcurrentDownloads = 1
        self.lastRequester = nil
    }
    
    fileprivate func enqueueDownloadTask(_ task: DownloadTask) {
        sync(queueLock) {
            self.downloadQueue.append(task)
            self.startNextDownloadTask()
        }
    }
    
    fileprivate func startNextDownloadTask() {
        downloadQueue = downloadQueue.filter{ !$0.cancelled }
        
        // This method must be called inside sync
        if currentDownloads >= maxConcurrentDownloads {
            return
        }
        
        if downloadQueue.count == 0 {
            return
        }
        
        var taskIndex = 0
        
        // TODO - task multiplexing only works for two different sources
        for (index, task) in downloadQueue.enumerated() {
            if lastRequester != nil && task.requester !== lastRequester! {
                taskIndex = index
            }
        }
       
        let downloadTask = downloadQueue.remove(at: taskIndex)
        lastRequester = downloadTask.requester
        
        currentDownloads = currentDownloads + 1
        
        downloadTask.internalTask = manager.retrieveImage(with: downloadTask.url, options: nil, progressBlock: nil, completionHandler: {
            (image, error, cacheType, url) in
            self.currentDownloads = self.currentDownloads - 1
            sync(self.queueLock) {
                if(!downloadTask.cancelled) {
                    downloadTask.completionHandler(image, error, cacheType, url as! NSURL)
                }
                self.startNextDownloadTask()
            }
        })
    }
    
    func retrieveImageFromCache(_ URL: Foundation.URL, requester: AnyObject) -> UIImage? {
        //print("Trying to get image from cache \(URL)")
        return manager.cache.retrieveImageInDiskCache(forKey: URL.absoluteString)
    }
    
    func addImageToCache(_ URL: Foundation.URL, image: UIImage) {
        //print("Adding Image to cache \(URL)")
        let data = UIImageJPEGRepresentation(image, 0.7)!
        addImageToCache(URL, originalData: data, image: image) { /* woop woop useless closure */ }
    }
    
    func addImageToCache(_ URL: Foundation.URL, originalData: Data, image: UIImage, completionHandler: @escaping () -> ()) {
        manager.cache.store(image, original: originalData, forKey: URL.absoluteString, toDisk: true, completionHandler: completionHandler)
    }
    
    func downloadImage(_ URL: Foundation.URL, requester: AnyObject, completionHandler: @escaping CompletionHandler) -> DownloadTask {
        let downloadTask = DownloadTask(URL: URL, requester: requester, syncRoot: queueLock, completionHandler: completionHandler)
        enqueueDownloadTask(downloadTask)
        return downloadTask
    }
}

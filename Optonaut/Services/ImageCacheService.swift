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
        let url: NSURL
        let requester: AnyObject
        let syncRoot: AnyObject
        let completionHandler: CompletionHandler
        var internalTask: RetrieveImageTask?
        var cancelled = false
        
        init(URL: NSURL, requester: AnyObject, syncRoot: AnyObject, completionHandler: CompletionHandler) {
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
    
    typealias CompletionHandler = ((image: UIImage?, error: NSError?, cacheType: CacheType, imageURL: NSURL?) -> ())

    static let sharedInstance = ImageManager(manager: KingfisherManager.sharedManager)
    
    private let manager: KingfisherManager
    private var downloadQueue: [DownloadTask]
    private var currentDownloads: Int
    private let maxConcurrentDownloads: Int
    private let queueLock: AnyObject
    
    private var lastRequester: AnyObject?
    
    init(manager: KingfisherManager) {
        self.manager = manager
        self.downloadQueue = [DownloadTask]()
        self.queueLock = NSObject()
        self.currentDownloads = 0
        self.maxConcurrentDownloads = 1
        self.lastRequester = nil
    }
    
    private func enqueueDownloadTask(task: DownloadTask) {
        sync(queueLock) {
            self.downloadQueue.append(task)
            self.startNextDownloadTask()
        }
    }
    
    private func startNextDownloadTask() {
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
        for (index, task) in downloadQueue.enumerate() {
            if lastRequester != nil && task.requester !== lastRequester! {
                taskIndex = index
            }
        }
       
        let downloadTask = downloadQueue.removeAtIndex(taskIndex)
        lastRequester = downloadTask.requester
        
        currentDownloads = currentDownloads + 1
        
        downloadTask.internalTask = manager.retrieveImageWithURL(downloadTask.url, optionsInfo: nil, progressBlock: nil, completionHandler: {
            (image, error, cacheType, url) in
            self.currentDownloads = self.currentDownloads - 1
            sync(self.queueLock) {
                if(!downloadTask.cancelled) {
                    downloadTask.completionHandler(image: image, error: error, cacheType: cacheType, imageURL: url)
                }
                self.startNextDownloadTask()
            }
        })
    }
    
    func retrieveImageFromCache(URL: NSURL, requester: AnyObject) -> UIImage? {
        //print("Trying to get image from cache \(URL)")
        return manager.cache.retrieveImageInDiskCacheForKey(URL.absoluteString)
    }
    
    func addImageToCache(URL: NSURL, image: UIImage) {
        //print("Adding Image to cache \(URL)")
        let data = UIImageJPEGRepresentation(image, 0.7)!
        addImageToCache(URL, originalData: data, image: image) { /* woop woop useless closure */ }
    }
    
    func addImageToCache(URL: NSURL, originalData: NSData, image: UIImage, completionHandler: () -> ()) {
        manager.cache.storeImage(image, originalData: originalData, forKey: URL.absoluteString, toDisk: true, completionHandler: completionHandler)
    }
    
    func downloadImage(URL: NSURL, requester: AnyObject, completionHandler: CompletionHandler) -> DownloadTask {
        let downloadTask = DownloadTask(URL: URL, requester: requester, syncRoot: queueLock, completionHandler: completionHandler)
        enqueueDownloadTask(downloadTask)
        return downloadTask
    }
}
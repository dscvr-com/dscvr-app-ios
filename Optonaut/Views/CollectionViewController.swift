//
//  CollectionViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Kingfisher
import SpriteKit

private class CollectionImageCache {
    
    typealias Callback = SKTexture -> Void
    typealias Item = (index: Int, image: SKTexture?, callback: Callback?, downloadTask: RetrieveImageDownloadTask?)
    
    private var items: [Item?]
    
    private static let cacheSize = 5
    
    private let imageManager = KingfisherManager()
    
    init() {
        items = [Item?](count: CollectionImageCache.cacheSize, repeatedValue: nil)
    }
    
    func get(index: Int, callback: Callback) {
        let item = items[index % CollectionImageCache.cacheSize]!
        if let image = item.image {
            callback(image)
        } else {
            items[index % CollectionImageCache.cacheSize]!.callback = callback
        }
    }
    
    func touch(index: Int, url: String) {
        let cacheIndex = index % CollectionImageCache.cacheSize
        if items[cacheIndex] == nil || items[cacheIndex]!.index != index {
            
            if let downloadTask = items[cacheIndex]?.downloadTask {
                downloadTask.cancel()
            }
            
            items[cacheIndex] = (index: index, image: nil, callback: nil, downloadTask: nil)
            
            let downloadTask = imageManager.downloader.downloadImageWithURL(
                NSURL(string: url)!,
                progressBlock: nil,
                completionHandler: { [weak self] (image, error, _, _) in
                    if let image = image {
                        let tex = SKTexture(image: image)
                        self?.items[cacheIndex]!.image = tex
                        self?.items[cacheIndex]!.downloadTask = nil
                        self?.items[cacheIndex]!.callback?(tex)
                    }
                    if let error = error {
                        print("KingfisherManager Download Error")
                        print(error)
                    }
                }
            )
            
            items[cacheIndex]!.downloadTask = downloadTask
            
        }
    }
}

private let reuseIdentifier = "Cell"

class CollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let viewModel = FeedViewModel()
    internal var items = [Optograph]()
    private let imageCache = CollectionImageCache()
    private let queue = dispatch_queue_create("collection_view", DISPATCH_QUEUE_SERIAL)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        collectionView!.registerClass(CollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        collectionView!.pagingEnabled = true
        
        automaticallyAdjustsScrollViewInsets = false

        
        collectionView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleUI"))
        
        CoreMotionRotationSource.Instance.start()
        
        viewModel.results.producer
            .on(
                next: { results in
                    self.items = results.models
                    self.collectionView!.performBatchUpdates({
                        if !results.delete.isEmpty {
                            self.collectionView!.deleteItemsAtIndexPaths(results.delete.map { NSIndexPath(forRow: $0, inSection: 0) })
                        }
                        if !results.update.isEmpty {
                            self.collectionView!.reloadItemsAtIndexPaths(results.update.map { NSIndexPath(forRow: $0, inSection: 0) })
                        }
                        if !results.insert.isEmpty {
                            self.collectionView!.insertItemsAtIndexPaths(results.insert.map { NSIndexPath(forRow: $0, inSection: 0) })
                        }
                    }, completion: nil)
                }
            )
            .start()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.refreshNotification.notify(())
        
        tabController!.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CollectionViewCell
    
        cell.reset(items[indexPath.row])
        cell.navigationController = navigationController as? NavigationController
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return view.frame.size
    }
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? CollectionViewCell else {
            return
        }
        
        cell.willDisplay()
        
        dispatch_async(queue) {
            let startIndex = max(0, indexPath.row - 2)
            let endIndex = min(self.items.count - 1, indexPath.row + 2)
            
            for index in startIndex...endIndex {
                let url = ImageURL(self.items[index].leftTextureAssetID, width: 2048)
                self.imageCache.touch(index, url: url)
            }
            
            self.imageCache.get(indexPath.row) { [weak self] image in
                if self?.collectionView?.indexPathsForVisibleItems().contains(indexPath) == true {
                    cell.setImage(image)
                }
            }
        }
        
        if indexPath.row > items.count - 3 {
            viewModel.loadMoreNotification.notify(())
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        (cell as! CollectionViewCell).didEndDisplay()
    }
    
    func toggleUI() {
        let uiVisible = !collectionView!.scrollEnabled
        collectionView!.scrollEnabled = uiVisible
        (collectionView!.visibleCells().first! as! CollectionViewCell).toggleUI()
        
        UIApplication.sharedApplication().setStatusBarHidden(!uiVisible, withAnimation: .None)
        
        tabController!.toggleUI()
    }

}

// MARK: - UITabBarControllerDelegate
extension CollectionViewController: TabControllerDelegate {
    
    func jumpToTop() {
        collectionView!.setContentOffset(CGPointZero, animated: true)
    }
    
}

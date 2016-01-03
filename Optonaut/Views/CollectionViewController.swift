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
import Async

private class CollectionImageCache {
    
    typealias Callback = SKTexture -> Void
    typealias Item = (index: Int, image: SKTexture?, callback: Callback?, downloadTask: RetrieveImageDownloadTask?)
    
    private var items: [Item?]
    private var optographs: [Optograph] {
        return optographsGetter()
    }
    private let optographsGetter: () -> [Optograph]
    
    private static let cacheSize = 5
    
    private let imageManager = KingfisherManager()
    
    private var activeIndex = 0
    
    init(optographsGetter: () -> [Optograph]) {
        items = [Item?](count: CollectionImageCache.cacheSize, repeatedValue: nil)
        self.optographsGetter = optographsGetter
        
//        imageManager.cache.
//        imageManager.cache.maxMemoryCost = UInt(NSProcessInfo.processInfo().physicalMemory) / 4
    }
    
    func get(index: Int, force: Bool, callback: Callback) -> Bool {
        
        if force {
            update(index)
        }
        
        guard let item = items[index % CollectionImageCache.cacheSize] else {
            return false
        }
        
        if item.index != index {
            return false
        }
        
        if let image = item.image {
            callback(image)
        } else {
            items[index % CollectionImageCache.cacheSize]!.callback = callback
        }
        
        return true
    }
    
    func touch(activeIndex: Int) {
        self.activeIndex = activeIndex
        
        let startIndex = max(0, activeIndex - 2)
        let endIndex = min(optographs.count - 1, activeIndex + 2)
        
        for index in startIndex...endIndex {
            update(index)
        }
    }
    
    private func update(index: Int) {
        let cacheIndex = index % CollectionImageCache.cacheSize
        if items[cacheIndex] == nil || items[cacheIndex]!.index != index {
            
            if let downloadTask = items[cacheIndex]?.downloadTask {
                downloadTask.cancel()
                print("cancel \(index)")
            }
            
            items[cacheIndex] = (index: index, image: nil, callback: nil, downloadTask: nil)
            
            let url = ImageURL(optographs[index].leftTextureAssetID, width: 2048)
            let downloadTask = imageManager.downloader.downloadImageWithURL(
                NSURL(string: url)!,
                options: (forceRefresh: false, lowPriority: activeIndex != index, cacheMemoryOnly: false, shouldDecode: false, queue: dispatch_get_main_queue(), scale: 1.0),
                progressBlock: nil,
                completionHandler: { [weak self] (image, error, _, _) in
                    if let image = image {
                        let tex = SKTexture(image: image)
                        self?.items[cacheIndex]!.image = tex
                        self?.items[cacheIndex]!.downloadTask = nil
                        self?.items[cacheIndex]!.callback?(tex)
                        self?.items[cacheIndex]!.callback = nil
                    }
                    if let error = error {
                        print(error)
                    }
                }
            )
            
            items[cacheIndex]!.downloadTask = downloadTask
        }
    }
    
    func delete(indices: [Int]) {
        var count = 0
        for index in indices {
            let shiftedIndex = index - count
            if let item = items.filter({ $0?.index == shiftedIndex }).first! {
                item.downloadTask?.cancel()
                
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
            update(minIndex + lowerShiftIndexOffset)
        }
    }
}

private let reuseIdentifier = "Cell"

class CollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let viewModel = FeedViewModel()
    internal var optographs = [Optograph]()
    private var imageCache: CollectionImageCache!
    private let queue = dispatch_queue_create("collection_view", DISPATCH_QUEUE_SERIAL)
    private let debouncer: Debouncer
    
    private let refreshControl = UIRefreshControl()
    
    
    required override init(collectionViewLayout: UICollectionViewLayout) {
        debouncer = Debouncer(queue: queue, delay: 0.1)
        
        super.init(collectionViewLayout: collectionViewLayout)
        
        imageCache = CollectionImageCache(optographsGetter: {
            return self.optographs
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        refreshControl.rac_signalForControlEvents(.ValueChanged).toSignalProducer().startWithNext { _ in
            self.viewModel.refreshNotification.notify(())
            Async.main(after: 10) { self.refreshControl.endRefreshing() }
        }
        refreshControl.bounds = CGRect(x: refreshControl.bounds.origin.x, y: 5, width: refreshControl.bounds.width, height: refreshControl.bounds.height)
        collectionView!.addSubview(refreshControl)

        // Register cell classes
        collectionView!.registerClass(CollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        collectionView!.pagingEnabled = true
        
        automaticallyAdjustsScrollViewInsets = false

        
        collectionView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleUI"))
        
        CoreMotionRotationSource.Instance.start()
        
        viewModel.results.producer
            .retryUntil(0.1, onScheduler: QueueScheduler(queue: queue)) { [weak self] in self?.collectionView!.decelerating == false && self?.collectionView!.dragging == false }
            .observeOnMain()
            .on(next: { [weak self] results in
                if let strongSelf = self {
                    let visibleOptograph: Optograph? = strongSelf.optographs.isEmpty ? nil : strongSelf.optographs[strongSelf.collectionView!.indexPathsForVisibleItems().first!.row]
                    strongSelf.optographs = results.models
                    
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                        strongSelf.collectionView!.performBatchUpdates({
                            strongSelf.imageCache.delete(results.delete)
                            strongSelf.imageCache.insert(results.insert)
                            strongSelf.collectionView!.deleteItemsAtIndexPaths(results.delete.map { NSIndexPath(forRow: $0, inSection: 0) })
                            strongSelf.collectionView!.reloadItemsAtIndexPaths(results.update.map { NSIndexPath(forRow: $0, inSection: 0) })
                            strongSelf.collectionView!.insertItemsAtIndexPaths(results.insert.map { NSIndexPath(forRow: $0, inSection: 0) })
                        }, completion: { _ in
                            if let visibleOptograph = visibleOptograph, visibleRow = strongSelf.optographs.indexOf({ $0.ID == visibleOptograph.ID }) where !strongSelf.refreshControl.refreshing {
                                strongSelf.collectionView!.contentOffset = CGPoint(x: 0, y: CGFloat(visibleRow) * strongSelf.view.frame.height)
                            }
                            strongSelf.refreshControl.endRefreshing()
                            CATransaction.commit()
                        })
                }
            })
            .start()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.refreshNotification.notify(())
        
        tabController!.delegate = self
        
        RotationService.sharedInstance.rotationEnable()
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        RotationService.sharedInstance.rotationDisable()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        tabController!.showUI()
        
        if let rotationSignal = RotationService.sharedInstance.rotationSignal {
            rotationSignal
                .skipRepeats()
                .filter([.LandscapeLeft, .LandscapeRight])
//                .takeWhile { [weak self] _ in self?.viewModel.viewIsActive.value ?? false }
                .take(1)
                .observeOn(UIScheduler())
                .observeNext { [weak self] orientation in self?.pushViewer(orientation) }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return optographs.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CollectionViewCell
    
        cell.reset(optographs[indexPath.row])
        cell.navigationController = navigationController as? NavigationController
        cell.deleteCallback = { [weak self] in
            self?.viewModel.refreshNotification.notify(())
        }
    
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
        
        print("will disp \(indexPath.row)")
        
        cell.willDisplay()
        
        let imageCallback = { [weak self] (image: SKTexture) in
            if self?.collectionView?.indexPathsForVisibleItems().contains(indexPath) == true {
                cell.setImage(image)
            }
        }
        
        dispatch_async(queue) { [weak self] in
            if self?.imageCache.get(indexPath.row, force: false, callback: imageCallback) == false {
                print("oops")
                self?.debouncer.debounce { [weak self] in
                    self?.imageCache.get(indexPath.row, force: true, callback: imageCallback)
                }
            }
        }
        
        debouncer.debounce { [weak self] in
            self?.imageCache.touch(indexPath.row)
        }
        
        if indexPath.row > optographs.count - 3 {
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
        
        if uiVisible {
            tabController!.showUI()
        } else {
            tabController!.hideUI()
        }
    }
    
    private func pushViewer(orientation: UIInterfaceOrientation) {
        guard let index = collectionView!.indexPathsForVisibleItems().first?.row else {
            return
        }
        
        let viewerViewController = ViewerViewController(orientation: orientation, optograph: optographs[index])
        navigationController?.pushViewController(viewerViewController, animated: false)
//        viewModel.increaseViewsCount()
    }

}

// MARK: - UITabBarControllerDelegate
extension CollectionViewController: TabControllerDelegate {
    
    func jumpToTop() {
        viewModel.refreshNotification.notify(())
//        collectionView!.setContentOffset(CGPointZero, animated: true)
    }
    
}

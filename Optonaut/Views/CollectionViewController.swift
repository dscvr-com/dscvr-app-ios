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

private let reuseIdentifier = "Cell"

private let queue = dispatch_queue_create("collection_view", DISPATCH_QUEUE_SERIAL)

class CollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, RedNavbar {
    
    private let viewModel = FeedViewModel()
    internal var optographs = [Optograph]()
    private var imageCache: CollectionImageCache!
    private let cacheDebouncerGet: Debouncer
    private let cacheDebouncerTouch: Debouncer
    private let overlayDebouncer: Debouncer
    
    private let refreshControl = UIRefreshControl()
    private let overlayView = OverlayView()
    
    private let uiHidden = MutableProperty<Bool>(false)
    
    private var overlayAnimating = false
    
    
    required override init(collectionViewLayout: UICollectionViewLayout) {
        cacheDebouncerGet = Debouncer(queue: queue, delay: 0.1)
        cacheDebouncerTouch = Debouncer(queue: queue, delay: 0.1)
        overlayDebouncer = Debouncer(queue: dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), delay: 0.01)
        
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
        
        title = String.iconWithName(.LogoText)
        
        let searchButton = UILabel(frame: CGRect(x: 0, y: -2, width: 24, height: 24))
        searchButton.text = String.iconWithName(.Search)
        searchButton.textColor = .whiteColor()
        searchButton.font = UIFont.iconOfSize(24)
        searchButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushSearch"))
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: searchButton)
        
        let activityButton = UILabel(frame: CGRect(x: 0, y: -2, width: 24, height: 24))
        activityButton.text = String.iconWithName(.Bell)
        activityButton.textColor = .whiteColor()
        activityButton.font = UIFont.iconOfSize(24)
        activityButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushActivity"))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityButton)

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
        
        collectionView!.delegate = self
        
        collectionView!.pagingEnabled = true
        
        automaticallyAdjustsScrollViewInsets = false
        
        collectionView!.delaysContentTouches = false
        
        edgesForExtendedLayout = .None

        
        CoreMotionRotationSource.Instance.start()
        
        viewModel.results.producer
            .retryUntil(0.1, onScheduler: QueueScheduler(queue: queue)) { [weak self] in self?.collectionView!.decelerating == false && self?.collectionView!.dragging == false }
            .observeOnMain()
            .on(next: { [weak self] results in
                if let strongSelf = self {
                    let visibleOptograph: Optograph? = strongSelf.optographs.isEmpty ? nil : strongSelf.optographs[strongSelf.collectionView!.indexPathsForVisibleItems().first!.row]
                    let before = strongSelf.optographs.count
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
                            if (!results.delete.isEmpty || !results.insert.isEmpty) && !strongSelf.refreshControl.refreshing {
                                if let visibleOptograph = visibleOptograph, visibleRow = strongSelf.optographs.indexOf({ $0.ID == visibleOptograph.ID }) {
                                    strongSelf.collectionView!.contentOffset = CGPoint(x: 0, y: CGFloat(visibleRow) * strongSelf.view.frame.height)
                                }
                            }
                            strongSelf.refreshControl.endRefreshing()
                            CATransaction.commit()
                        })
                }
            })
            .start()
        
        let topOffset = navigationController!.navigationBar.frame.height + 20
        overlayView.frame = CGRect(x: 0, y: topOffset, width: view.frame.width, height: view.frame.height - topOffset)
        overlayView.uiHidden = uiHidden
        overlayView.navigationController = navigationController as? NavigationController
        overlayView.rac_hidden <~ uiHidden
        overlayView.deleteCallback = { [weak self] in
            self?.overlayView.optograph = nil
            self?.viewModel.refreshNotification.notify(())
        }
        view.addSubview(overlayView)
        
        uiHidden.producer.startWithNext { [weak self] hidden in
            self?.navigationController?.setNavigationBarHidden(hidden, animated: false)
            UIApplication.sharedApplication().setStatusBarHidden(hidden, withAnimation: .None)
            
            self?.collectionView!.scrollEnabled = !hidden
            
            if hidden {
                self?.tabController?.hideUI()
            } else {
                self?.tabController?.showUI()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        uiHidden.value = false
        
        viewModel.refreshNotification.notify(())
        
        tabController!.delegate = self
        
        view.bounds = UIScreen.mainScreen().bounds
        
        RotationService.sharedInstance.rotationEnable()
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        RotationService.sharedInstance.rotationDisable()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.iconOfSize(26),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        navigationController?.navigationBar.setTitleVerticalPositionAdjustment(3, forBarMetrics: .Default)
        
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.frame = UIScreen.mainScreen().bounds
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
    
        cell.reset()
        cell.uiHidden = uiHidden
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? CollectionViewCell else {
            return
        }
        
        cell.willDisplay()
        
        let imageCallback = { [weak self] (image: SKTexture, isPreview: Bool) in
            if self?.collectionView?.indexPathsForVisibleItems().contains(indexPath) == true {
                cell.setImage(image, isPreview: isPreview)
            }
        }
        
        dispatch_async(queue) { [weak self] in
            if self?.imageCache.get(indexPath.row, force: false, callback: imageCallback) == false {
                self?.cacheDebouncerGet.debounce { [weak self] in
                    self?.imageCache.get(indexPath.row, force: true, callback: imageCallback)
                }
            }
        }
        
        if overlayView.optograph == nil {
            overlayView.optograph = optographs[indexPath.row]
        }
        
        cacheDebouncerTouch.debounce { [weak self] in
            self?.imageCache.touch(indexPath.row)
        }
        
        if indexPath.row > optographs.count - 3 {
            viewModel.loadMoreNotification.notify(())
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        (cell as! CollectionViewCell).didEndDisplay()
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let height = view.frame.height
        let offset = scrollView.contentOffset.y
        
        if !overlayAnimating {
            let relativeOffset = offset % height
            let percentage = relativeOffset / height
            var opacity: CGFloat = 0
            if percentage > 0.8 || percentage < 0.2 {
                if scrollView.decelerating && overlayView.alpha == 0 {
                    overlayAnimating = true
                    dispatch_async(dispatch_get_main_queue()) {
                        UIView.animateWithDuration(0.2,
                            delay: 0,
                            options: [.AllowUserInteraction],
                            animations: {
                                self.overlayView.alpha = 1
                            }, completion: nil)
                    }
                    return
                }
                
                let normalizedPercentage = percentage < 0.2 ? percentage : 1 - percentage
                opacity = -10 * normalizedPercentage + 2
            }
            
            overlayView.alpha = opacity
        }
        
        let overlayOptograph = optographs[Int(round(offset / height))]
        if overlayOptograph.ID != overlayView.optograph?.ID {
            overlayView.optograph = overlayOptograph
        }
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        overlayAnimating = false
        overlayView.layer.removeAllAnimations()
    }

    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        overlayAnimating = false
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
        collectionView!.setContentOffset(CGPointZero, animated: true)
    }
    
    func scrollToOptograph(optograph: Optograph) {
        let row = optographs.indexOf({ $0.ID == optograph.ID })
        collectionView!.scrollToItemAtIndexPath(NSIndexPath(forRow: row!, inSection: 0), atScrollPosition: .Top, animated: true)
    }
    
}

private class CollectionImageCache {
    
    private enum Downloaded { case None, Preview, Full }
    
    typealias Callback = (SKTexture, isPreview: Bool) -> Void
//    typealias Item = (index: Int, image: SKTexture?, callback: Callback?, downloadTask: RetrieveImageDownloadTask?)
    typealias Item = (index: Int, image: SKTexture?, callback: Callback?, previewDownloadTask: RetrieveImageTask?, fullDownloadTask: RetrieveImageTask?)
    
    private var items: [Item?]
    private var optographs: [Optograph] {
        return optographsGetter()
    }
    private let optographsGetter: () -> [Optograph]
    
    private static let cacheSize = 5
    
//    private let imageManager = KingfisherManager()
    
    private var activeIndex = 0
    
    init(optographsGetter: () -> [Optograph]) {
        items = [Item?](count: CollectionImageCache.cacheSize, repeatedValue: nil)
        self.optographsGetter = optographsGetter
        
        KingfisherManager.sharedManager.downloader.downloadTimeout = 60
        
//        imageManager.cache.maxMemoryCost = UInt(NSProcessInfo.processInfo().physicalMemory) / 4
    }
    
    func get(index: Int, force: Bool, callback: Callback) -> Bool {
        
        if force {
            update(index, callback: callback)
        }
        
        guard let item = items[index % CollectionImageCache.cacheSize] else {
            return false
        }
        
        if item.index != index {
            return false
        }
        
        if let image = item.image {
            callback(image, isPreview: item.fullDownloadTask != nil)
        }
        
        if item.fullDownloadTask != nil {
            items[index % CollectionImageCache.cacheSize]!.callback = callback
        }
        
        return true
    }
    
    func touch(activeIndex: Int) {
        self.activeIndex = activeIndex
        
        let startIndex = max(0, activeIndex - 2)
        let endIndex = min(optographs.count - 1, activeIndex + 2)
        
        for index in startIndex...endIndex {
            update(index, callback: nil)
        }
    }
    
    private func update(index: Int, callback: Callback?) {
        let cacheIndex = index % CollectionImageCache.cacheSize
        if items[cacheIndex] == nil || items[cacheIndex]!.index != index {
            
            items[cacheIndex]?.previewDownloadTask?.cancel()
            items[cacheIndex]?.fullDownloadTask?.cancel()
            
            var item: Item = (index: index, image: nil, callback: nil, previewDownloadTask: nil, fullDownloadTask: nil)
            
            item.fullDownloadTask = KingfisherManager.sharedManager.retrieveImageWithURL(
                NSURL(string: ImageURL(optographs[index].leftTextureAssetID, width: 2048))!,
                optionsInfo: nil,
//                optionsInfo: [.Options(.LowPriority)],
                progressBlock: nil,
                completionHandler: { [weak self] (image, error, _, _) in
                    dispatch_async(queue) {
                        self?.items[cacheIndex]?.previewDownloadTask?.cancel()
                        
                        if let image = image where self?.items[cacheIndex] != nil {
                            let tex = SKTexture(image: image)
                            self?.items[cacheIndex]?.image = tex
                            self?.items[cacheIndex]?.fullDownloadTask = nil
                            self?.items[cacheIndex]?.callback?(tex, isPreview: false)
                            self?.items[cacheIndex]?.callback = nil
                        }
                    }
                }
            )
            
            item.previewDownloadTask = KingfisherManager.sharedManager.retrieveImageWithURL(
                NSURL(string: ImageURL(optographs[index].leftTextureAssetID, width: 128))!,
                optionsInfo: nil,
                progressBlock: nil,
                completionHandler: { [weak self] (image, error, _, _) in
                    dispatch_async(queue) {
                        if self?.items[cacheIndex]?.fullDownloadTask == nil {
                            return
                        }
                        
                        if let image = image {
                            let tex = SKTexture(image: image)
                            self?.items[cacheIndex]?.image = tex
                            self?.items[cacheIndex]?.previewDownloadTask = nil
                            self?.items[cacheIndex]?.callback?(tex, isPreview: true)
                        }
                    }
                }
            )
            
            items[cacheIndex] = item
        }
    }
    
    func delete(indices: [Int]) {
        var count = 0
        for index in indices {
            let shiftedIndex = index - count
            if let item = items.filter({ $0?.index == shiftedIndex }).first! {
                item.previewDownloadTask?.cancel()
                item.fullDownloadTask?.cancel()
                
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
            update(minIndex + lowerShiftIndexOffset, callback: nil)
        }
    }
}

private class OverlayViewModel {
    
    var optograph: Optograph?
    
    let likeCount = MutableProperty<Int>(0)
    let liked = MutableProperty<Bool>(false)
    let textToggled = MutableProperty<Bool>(false)
    
    func bind(optograph: Optograph) {
        self.optograph = optograph
        
        likeCount.value = optograph.starsCount
        liked.value = optograph.isStarred
        textToggled.value = false
    }
    
    func toggleLike() {
        let starredBefore = liked.value
        let starsCountBefore = likeCount.value
        
        SignalProducer<Bool, ApiError>(value: starredBefore)
            .flatMap(.Latest) { followedBefore in
                starredBefore
                    ? ApiService<EmptyResponse>.delete("optographs/\(self.optograph!.ID)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(self.optograph!.ID)/star", parameters: nil)
            }
            .on(
                started: {
                    self.liked.value = !starredBefore
                    self.likeCount.value += starredBefore ? -1 : 1
                },
                failed: { _ in
                    self.liked.value = starredBefore
                    self.likeCount.value = starsCountBefore
                },
                completed: updateModel
            )
            .start()
    }
    
    
    private func updateModel() {
        optograph!.isStarred = liked.value
        optograph!.starsCount = likeCount.value
        
        try! optograph!.insertOrUpdate()
    }
}

private class OverlayView: UIView {
    
    private let viewModel = OverlayViewModel()
    
    weak var uiHidden: MutableProperty<Bool>!
    weak var navigationController: NavigationController?
    
    var deleteCallback: (() -> ())?
    
    private var optograph: Optograph? {
        didSet {
            if let optograph = optograph {
                viewModel.bind(optograph)
                
                avatarImageView.kf_setImageWithURL(NSURL(string: ImageURL(optograph.person.avatarAssetID, width: 47, height: 47))!)
                personNameView.text = optograph.person.displayName
                locationTextView.text = optograph.location?.text
                dateView.text = optograph.createdAt.longDescription
                textView.text = optograph.text
                
                if let location = optograph.location {
                    locationTextView.text = "\(location.text), \(location.country)"
                    personNameView.anchorInCorner(.TopLeft, xPad: 75, yPad: 17, width: 200, height: 18)
                    locationTextView.anchorInCorner(.TopLeft, xPad: 75, yPad: 37, width: 200, height: 13)
                } else {
                    personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
                }
                
            }
        }
    }
    
    private let whiteBackground = UIView()
    private let avatarImageView = UIImageView()
    private let personNameView = BoundingLabel()
    private let locationTextView = UILabel()
    private let optionsButtonView = BoundingButton()
    private let likeButtonView = BoundingButton()
    private let likeCountView = UILabel()
    private let dateView = UILabel()
    private let textView = UILabel()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        whiteBackground.backgroundColor = UIColor.whiteColor().alpha(0.95)
        addSubview(whiteBackground)
        
        avatarImageView.layer.cornerRadius = 23.5
//        avatarImageView.layer.borderColor = UIColor.whiteColor().CGColor
//        avatarImageView.layer.borderWidth = 1.5
        avatarImageView.backgroundColor = .whiteColor()
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        addSubview(avatarImageView)
        
        personNameView.font = UIFont.displayOfSize(15, withType: .Regular)
        personNameView.textColor = .Accent
        personNameView.userInteractionEnabled = true
        personNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        addSubview(personNameView)
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(28)
        optionsButtonView.setTitle(String.iconWithName(.MoreHor), forState: .Normal)
        optionsButtonView.setTitleColor(UIColor.LightGrey, forState: .Normal)
        optionsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "didTapOptions"))
        addSubview(optionsButtonView)
        
        locationTextView.font = UIFont.displayOfSize(11, withType: .Light)
        locationTextView.textColor = UIColor(0x3c3c3c)
        addSubview(locationTextView)
        
        likeButtonView.layer.cornerRadius = 14
        likeButtonView.clipsToBounds = true
        likeButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleLike"))
        likeButtonView.setTitle(String.iconWithName(.HeartFilled), forState: .Normal)
        addSubview(likeButtonView)
        
        likeCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        likeCountView.textColor = .whiteColor()
        likeCountView.textAlignment = .Right
        addSubview(likeCountView)
        
        likeCountView.rac_text <~ viewModel.likeCount.producer.map { "\($0)" }
        
        viewModel.liked.producer.startWithNext { [weak self] liked in
            if let strongSelf = self {
                if liked {
                    strongSelf.likeButtonView.anchorInCorner(.BottomRight, xPad: 16, yPad: 152, width: 31, height: 28)
                    strongSelf.likeButtonView.backgroundColor = .Accent
                    strongSelf.likeButtonView.titleLabel?.font = UIFont.iconOfSize(15)
                } else {
                    strongSelf.likeButtonView.anchorInCorner(.BottomRight, xPad: 16, yPad: 152, width: 23, height: 28)
                    strongSelf.likeButtonView.backgroundColor = .clearColor()
                    strongSelf.likeButtonView.titleLabel?.font = UIFont.iconOfSize(24)
                }
                strongSelf.likeCountView.align(.ToTheLeftCentered, relativeTo: strongSelf.likeButtonView, padding: 8, width: 40, height: 13)
            }
        }
        
        dateView.font = UIFont.displayOfSize(11, withType: .Thin)
        dateView.textColor = UIColor(0xbbbbbb)
        dateView.textAlignment = .Right
        addSubview(dateView)
        
        textView.font = UIFont.displayOfSize(14, withType: .Regular)
        textView.textColor = .whiteColor()
        addSubview(textView)
        
        viewModel.textToggled.producer.startWithNext { [weak self] toggled in
            if let strongSelf = self, text = strongSelf.optograph?.text {
                let textHeight = calcTextHeight(text, withWidth: strongSelf.frame.width - 36, andFont: UIFont.displayOfSize(13, withType: .Light))
                let displayedTextHeight = toggled && textHeight > 16 ? textHeight : 15
                let bottomHeight: CGFloat = 50 + (text.isEmpty ? 0 : displayedTextHeight + 11)
                
                UIView.setAnimationCurve(.EaseInOut)
                UIView.animateWithDuration(0.3) {
//                    strongSelf.frame = CGRect(x: 0, y: strongSelf.frame.height - 108 - bottomHeight, width: strongSelf.frame.width, height: bottomHeight)
                }
                
                strongSelf.textView.anchorInCorner(.BottomLeft, xPad: 16, yPad: 126, width: strongSelf.frame.width - 36, height: displayedTextHeight)
                
                strongSelf.textView.numberOfLines = toggled ? 0 : 1
            }
        }
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        whiteBackground.frame = CGRect(x: 0, y: 0, width: frame.width, height: 66)
        avatarImageView.anchorInCorner(.TopLeft, xPad: 16, yPad: 9.5, width: 47, height: 47)
        optionsButtonView.anchorInCorner(.TopRight, xPad: 16, yPad: 21, width: 24, height: 24)
        dateView.anchorInCorner(.TopRight, xPad: 46, yPad: 27, width: 70, height: 13)
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.hidden && subview.alpha > 0 && subview.userInteractionEnabled && subview.pointInside(convertPoint(point, toView: subview), withEvent: event) {
                return true
            }
        }
        return false
    }
    
    @objc
    private func toggleText() {
        viewModel.textToggled.value = !viewModel.textToggled.value
    }
    
    @objc
    private func toggleLike() {
//        KingfisherManager.sharedManager.cache.clearDiskCache()
//        KingfisherManager.sharedManager.cache.clearMemoryCache()
        viewModel.toggleLike()
    }
    
    @objc
    private func pushProfile() {
        navigationController?.pushViewController(ProfileTableViewController(personID: viewModel.optograph!.person.ID), animated: true)
    }
    
    @objc
    private func pushSearch() {
        navigationController?.pushViewController(SearchTableViewController(), animated: true)
    }
    
}

extension OverlayView: OptographOptions {
    
    @objc
    func didTapOptions() {
        showOptions(viewModel.optograph!, deleteCallback: deleteCallback)
    }
    
}
//
//  CollectionViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SpriteKit
import Async
import Kingfisher

typealias Direction = (phi: Float, theta: Float)

protocol OptographCollectionViewModel {
    var isActive: MutableProperty<Bool> { get }
    var results: MutableProperty<TableViewResults<Optograph>> { get }
    func refresh()
}


class OptographCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, RedNavbar {
    
    private let queue = dispatch_queue_create("collection_view", DISPATCH_QUEUE_SERIAL)
    
    private let viewModel: OptographCollectionViewModel
    private let imageCache: CollectionImageCache
    private let overlayDebouncer: Debouncer
    
    private var optographIDs: [UUID] = []
    private var optographDirections: [UUID: Direction] = [:]
    
    private let refreshControl = UIRefreshControl()
    private let overlayView = OverlayView()
    
    private let uiHidden = MutableProperty<Bool>(false)
    
    private var overlayIsAnimating = false
    
    private var isVisible = false
    
    init(viewModel: OptographCollectionViewModel) {
        self.viewModel = viewModel
        
        overlayDebouncer = Debouncer(queue: dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), delay: 0.01)
        
        let textureSize = getTextureWidth(UIScreen.mainScreen().bounds.width, hfov: HorizontalFieldOfView)
        imageCache = CollectionImageCache(textureSize: textureSize)
        
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        imageCache.onMemoryWarning()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cardboardButton = UILabel(frame: CGRect(x: 0, y: -2, width: 24, height: 24))
        cardboardButton.text = String.iconWithName(.Cardboard)
        cardboardButton.textColor = .whiteColor()
        cardboardButton.font = UIFont.iconOfSize(24)
        cardboardButton.userInteractionEnabled = true
        cardboardButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OptographCollectionViewController.showCardboardAlert)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cardboardButton)
        
        refreshControl.rac_signalForControlEvents(.ValueChanged).toSignalProducer().startWithNext { [weak self] _ in
            self?.viewModel.refresh()
            Async.main(after: 10) { [weak self] in self?.refreshControl.endRefreshing() }
        }
        refreshControl.bounds = CGRect(x: refreshControl.bounds.origin.x, y: 5, width: refreshControl.bounds.width, height: refreshControl.bounds.height)
        collectionView!.addSubview(refreshControl)
        
        // Register cell classes
        collectionView!.registerClass(OptographCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        collectionView!.delegate = self
        
        collectionView!.pagingEnabled = true
        
        automaticallyAdjustsScrollViewInsets = false
        
        collectionView!.delaysContentTouches = false
        
        edgesForExtendedLayout = .None
        
        viewModel.results.producer
            .filter { $0.changed }
            .retryUntil(0.1, onScheduler: QueueScheduler(queue: queue)) { [weak self] in self?.collectionView!.decelerating == false && self?.collectionView!.dragging == false }
            .delayAllUntil(viewModel.isActive.producer)
            .observeOnMain()
            .on(next: { [weak self] results in
                if let strongSelf = self {
                    let visibleOptographID: UUID? = strongSelf.optographIDs.isEmpty ? nil : strongSelf.optographIDs[strongSelf.collectionView!.indexPathsForVisibleItems().first!.row]
                    strongSelf.optographIDs = results.models.map { $0.ID }
                    for optograph in results.models {
                        if strongSelf.optographDirections[optograph.ID] == nil {
                            strongSelf.optographDirections[optograph.ID] = (phi: Float(optograph.directionPhi), theta: Float(optograph.directionTheta))
                        }
                    }
                    
                    if results.models.count == 1 {
                        strongSelf.collectionView!.reloadData()
                    } else {
                        CATransaction.begin()
                        CATransaction.setDisableActions(true)
                        strongSelf.collectionView!.performBatchUpdates({
                            strongSelf.imageCache.delete(results.delete)
                            strongSelf.imageCache.insert(results.insert)
                            strongSelf.collectionView!.deleteItemsAtIndexPaths(results.delete.map { NSIndexPath(forItem: $0, inSection: 0) })
                            strongSelf.collectionView!.reloadItemsAtIndexPaths(results.update.map { NSIndexPath(forItem: $0, inSection: 0) })
                            strongSelf.collectionView!.insertItemsAtIndexPaths(results.insert.map { NSIndexPath(forItem: $0, inSection: 0) })
                            }, completion: { _ in
                                if (!results.delete.isEmpty || !results.insert.isEmpty) && !strongSelf.refreshControl.refreshing {
                                    if let visibleOptographID = visibleOptographID, visibleRow = strongSelf.optographIDs.indexOf({ $0 == visibleOptographID }) {
                                        strongSelf.collectionView!.contentOffset = CGPoint(x: 0, y: CGFloat(visibleRow) * strongSelf.view.frame.height)
                                    }
                                }
                                strongSelf.refreshControl.endRefreshing()
                                CATransaction.commit()
                        })
                    }
                    
                }
                })
            .start()
        
        let topOffset = navigationController!.navigationBar.frame.height + 20
        overlayView.frame = CGRect(x: 0, y: topOffset, width: view.frame.width, height: view.frame.height - topOffset)
        overlayView.uiHidden = uiHidden
        overlayView.navigationController = navigationController as? NavigationController
        overlayView.parentViewController = self
        overlayView.rac_hidden <~ uiHidden
        view.addSubview(overlayView)
        
        uiHidden.producer.startWithNext { [weak self] hidden in
            self?.navigationController?.setNavigationBarHidden(hidden, animated: false)
            
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
        overlayView.alpha = 0
        
        if !optographIDs.isEmpty {
            lazyFadeInOverlay(delay: 0.3)
        }
        
        viewModel.isActive.value = true
        
        CoreMotionRotationSource.Instance.start()
        
        view.bounds = UIScreen.mainScreen().bounds
        
        RotationService.sharedInstance.rotationEnable()
        
        if let indexPath = collectionView!.indexPathsForVisibleItems().first, cell = collectionView!.cellForItemAtIndexPath(indexPath) {
            collectionView(collectionView!, willDisplayCell: cell, forItemAtIndexPath: indexPath)
        }
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // TODO - remove as soon as correct disposal is implemented.
        // imageCache.reset()
        
        RotationService.sharedInstance.rotationDisable()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        isVisible = true
        
        if !optographIDs.isEmpty {
            lazyFadeInOverlay(delay: 0)
        }
        
        tabController!.delegate = self
        
        updateNavbarAppear()
        
        updateTabs()
        
        tabController!.showUI()
        
        if let rotationSignal = RotationService.sharedInstance.rotationSignal {
            rotationSignal
                .skipRepeats()
                .filter([.LandscapeLeft, .LandscapeRight])
                .take(1)
                .observeOn(UIScheduler())
                .observeNext { [weak self] orientation in self?.pushViewer(orientation) }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        isVisible = false
        
        CoreMotionRotationSource.Instance.stop()
        
        viewModel.isActive.value = false
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
        return optographIDs.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! OptographCollectionViewCell
        
        cell.uiHidden = uiHidden
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return UIScreen.mainScreen().bounds.size
    }
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = cell as? OptographCollectionViewCell else {
            return
        }
        
        let optographID = optographIDs[indexPath.row]
        
        cell.direction = optographDirections[optographID]!
        cell.willDisplay()
        
        let cubeImageCache = imageCache.get(indexPath.row, optographID: optographID, side: .Left)
        cell.setCubeImageCache(cubeImageCache)
        
        cell.id = indexPath.row
        
        if StitchingService.isStitching() {
            imageCache.resetExcept(indexPath.row)
        } else {
            for i in [-2, -1, 1, 2] where indexPath.row + i > 0 && indexPath.row + i < optographIDs.count {
                let id = optographIDs[indexPath.row + i]
                let cubeIndices = cell.getVisibleAndAdjacentPlaneIndices(optographDirections[id]!)
                imageCache.touch(indexPath.row + i, optographID: id, side: .Left, cubeIndices: cubeIndices)
            }
        }
        
        if overlayView.optographID == nil {
            overlayView.optographID = optographID
        }
        
        if isVisible {
            lazyFadeInOverlay(delay: 0)
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let cell = cell as! OptographCollectionViewCell
        
        optographDirections[optographIDs[indexPath.row]] = cell.direction
        cell.didEndDisplay()
        
        imageCache.disable(indexPath.row)
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let height = view.frame.height
        let offset = scrollView.contentOffset.y
        
        if !overlayIsAnimating {
            let relativeOffset = offset % height
            let percentage = relativeOffset / height
            var opacity: CGFloat = 0
            if percentage > 0.8 || percentage < 0.2 {
                if scrollView.decelerating && overlayView.alpha == 0 {
                    overlayIsAnimating = true
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
        
        let overlayOptographID = optographIDs[Int(round(offset / height))]
        if overlayOptographID != overlayView.optographID {
            overlayView.optographID = overlayOptographID
        }
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        overlayIsAnimating = false
        overlayView.layer.removeAllAnimations()
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        overlayIsAnimating = false
    }
    
    override func cleanup() {
        for cell in collectionView!.visibleCells().map({ $0 as! OptographCollectionViewCell }) {
            cell.forgetTextures()
        }
        
        imageCache.reset()
    }
    
    private func pushViewer(orientation: UIInterfaceOrientation) {
        guard let index = collectionView!.indexPathsForVisibleItems().first?.row else {
            return
        }
        
//        let viewerViewController = ViewerViewController(orientation: orientation, optograph: Models.optographs[optographIDs[index]]!.model)
//        navigationController?.pushViewController(viewerViewController, animated: false)
    }
    
    private func lazyFadeInOverlay(delay delay: NSTimeInterval) {
        if overlayView.alpha == 0 && !overlayIsAnimating {
            overlayIsAnimating = true
            //            dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.2,
                                       delay: delay,
                                       options: [.AllowUserInteraction],
                                       animations: {
                                        self.overlayView.alpha = 1
                }, completion: { _ in
                    self.overlayIsAnimating = false
                }
            )
        }
    }
    
    dynamic private func showCardboardAlert() {
        let confirmAlert = UIAlertController(title: "Put phone in VR viewer", message: "Please turn your phone and put it into your VR viewer.", preferredStyle: .Alert)
        confirmAlert.addAction(UIAlertAction(title: "Continue", style: .Cancel, handler: { _ in return }))
        navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
    }
    
}

// MARK: - UITabBarControllerDelegate
extension OptographCollectionViewController: DefaultTabControllerDelegate {
    
    func jumpToTop() {
        viewModel.refresh()
        collectionView!.setContentOffset(CGPointZero, animated: true)
    }
    
    func scrollToOptograph(optographID: UUID) {
        let row = optographIDs.indexOf(optographID)
        collectionView!.scrollToItemAtIndexPath(NSIndexPath(forRow: row!, inSection: 0), atScrollPosition: .Top, animated: true)
    }
    
}

private class OverlayViewModel {
    
    var optographBox: ModelBox<Optograph>!
    
    var optograph: Optograph!
    
    func bind(optographID: UUID) {
        
        optographBox = Models.optographs[optographID]!
        
    }
}

private class OverlayView: UIView {
    
    private let viewModel = OverlayViewModel()
    
    weak var uiHidden: MutableProperty<Bool>!
    weak var navigationController: NavigationController?
    weak var parentViewController: UIViewController?
    
    var deleteCallback: (() -> ())?
    
    private var optographID: UUID? {
        didSet {
            if let optographID = optographID  {
                let optograph = Models.optographs[optographID]!.model
                
                viewModel.bind(optographID)
                
                dateView.text = optograph.createdAt.longDescription
                textView.text = optograph.text
            }
        }
    }
    
    private let whiteBackground = UIView()
    private let avatarImageView = UIImageView()
    private let personNameView = BoundingLabel()
    private let locationTextView = UILabel()
    private let optionsButtonView = BoundingButton()
    private let dateView = UILabel()
    private let textView = BoundingLabel()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        whiteBackground.backgroundColor = UIColor.whiteColor().alpha(0.95)
        addSubview(whiteBackground)
        
        avatarImageView.layer.cornerRadius = 23.5
        avatarImageView.backgroundColor = .whiteColor()
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        addSubview(avatarImageView)
        
        personNameView.font = UIFont.displayOfSize(15, withType: .Regular)
        personNameView.textColor = .Accent
        personNameView.userInteractionEnabled = true
        addSubview(personNameView)
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(21)
        optionsButtonView.setTitle(String.iconWithName(.More), forState: .Normal)
        optionsButtonView.setTitleColor(UIColor(0xc6c6c6), forState: .Normal)
        optionsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OverlayView.didTapOptions)))
        addSubview(optionsButtonView)
        
        locationTextView.font = UIFont.displayOfSize(11, withType: .Light)
        locationTextView.textColor = UIColor(0x3c3c3c)
        addSubview(locationTextView)
        
        dateView.font = UIFont.displayOfSize(11, withType: .Regular)
        dateView.textColor = UIColor(0xbbbbbb)
        dateView.textAlignment = .Right
        addSubview(dateView)
        
        textView.font = UIFont.displayOfSize(14, withType: .Regular)
        textView.textColor = .whiteColor()
        textView.userInteractionEnabled = true
        addSubview(textView)
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
    
}

extension OverlayView: OptographOptions {
    
    dynamic func didTapOptions() {
        showOptions(viewModel.optographBox.model.ID, deleteCallback: deleteCallback)
    }
    
}
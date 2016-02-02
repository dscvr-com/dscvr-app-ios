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
    func loadMore()
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
        
//        let searchButton = UILabel(frame: CGRect(x: 0, y: -2, width: 24, height: 24))
//        searchButton.text = String.iconWithName(.Cancel)
//        searchButton.textColor = .whiteColor()
//        searchButton.font = UIFont.iconOfSize(24)
//        searchButton.userInteractionEnabled = true
//        searchButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushSearch"))
//        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: searchButton)
        
        let cardboardButton = UILabel(frame: CGRect(x: 0, y: -2, width: 24, height: 24))
        cardboardButton.text = String.iconWithName(.Cardboard)
        cardboardButton.textColor = .whiteColor()
        cardboardButton.font = UIFont.iconOfSize(24)
        cardboardButton.userInteractionEnabled = true
        cardboardButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showCardboardAlert"))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cardboardButton)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
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
                                    // preserves scroll position
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
//        overlayView.deleteCallback = { [weak self] in
//            self?.overlayView.optographID = nil
//            self?.viewModel.refresh()
//        }
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
        
//        viewModel.isActive.producer
//            .skip(1)
//            .filter(isFalse)
//            .startWithNext { [weak self] _ in
//                self?.imageCache.reset()
//            }
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
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //imageCache.reset()
        
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
//                .takeWhile { [weak self] _ in self?.viewModel.viewIsActive.value ?? false }
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
        
        for i in [-2, -1, 1, 2] where indexPath.row + i > 0 && indexPath.row + i < optographIDs.count {
            let id = optographIDs[indexPath.row + i]
            let cubeIndices = cell.getVisibleAndAdjacentPlaneIndices(optographDirections[id]!)
            imageCache.touch(indexPath.row + i, optographID: id, side: .Left, cubeIndices: cubeIndices)
        }
        
        if overlayView.optographID == nil {
            overlayView.optographID = optographID
        }
        
        if isVisible {
            lazyFadeInOverlay(delay: 0)
        }
        
        if indexPath.row > optographIDs.count - 3 {
            viewModel.loadMore()
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
        
        let viewerViewController = ViewerViewController(orientation: orientation, optograph: Models.optographs[optographIDs[index]]!.model)
        navigationController?.pushViewController(viewerViewController, animated: false)
//        viewModel.increaseViewsCount()
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
//            }
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
    
    let likeCount = MutableProperty<Int>(0)
    let liked = MutableProperty<Bool>(false)
    let textToggled = MutableProperty<Bool>(false)
    
    enum UploadStatus { case Offline, Uploading, Uploaded }
    let uploadStatus = MutableProperty<UploadStatus>(.Uploaded)
    
    var optographBox: ModelBox<Optograph>!
    
    var optograph: Optograph!
    
    func bind(optographID: UUID) {
        
        optographBox = Models.optographs[optographID]!
        
        textToggled.value = false
        
        optographBox.producer.startWithNext { [weak self] optograph in
            self?.likeCount.value = optograph.starsCount
            self?.liked.value = optograph.isStarred
            
            if optograph.isPublished {
                self?.uploadStatus.value = .Uploaded
            } else if optograph.isUploading {
                self?.uploadStatus.value = .Uploading
            } else {
                self?.uploadStatus.value = .Offline
            }
        }
        
    }
    
    func toggleLike() {
        let starredBefore = liked.value
        let starsCountBefore = likeCount.value
        
        let optograph = optographBox.model
        
        SignalProducer<Bool, ApiError>(value: starredBefore)
            .flatMap(.Latest) { followedBefore in
                starredBefore
                    ? ApiService<EmptyResponse>.delete("optographs/\(optograph.ID)/star")
                    : ApiService<EmptyResponse>.post("optographs/\(optograph.ID)/star", parameters: nil)
            }
            .on(
                started: { [weak self] in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.isStarred = !starredBefore
                        box.model.starsCount += starredBefore ? -1 : 1
                    }
                },
                failed: { [weak self] _ in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.isStarred = starredBefore
                        box.model.starsCount = starsCountBefore
                    }
                }
            )
            .start()
    }
    
    func upload() {
        if !optographBox.model.isOnServer {
            let optograph = optographBox.model
            
            optographBox.update { box in
                box.model.isUploading = true
            }
            
            let postParameters = [
                "id": optograph.ID,
                "stitcher_version": StitcherVersion,
                "created_at": optograph.createdAt.toRFC3339String(),
            ]
            
            var putParameters: [String: AnyObject] = [
                "text": optograph.text,
                "is_private": optograph.isPrivate,
                "post_facebook": optograph.postFacebook,
                "post_twitter": optograph.postTwitter,
                "direction_phi": optograph.directionPhi,
                "direction_theta": optograph.directionTheta,
            ]
            if let locationID = optograph.locationID, location = Models.locations[locationID]?.model {
                putParameters["location"] = [
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                    "text": location.text,
                    "country": location.country,
                    "country_short": location.countryShort,
                    "place": location.place,
                    "region": location.region,
                    "poi": location.POI,
                ]
            }
            
            SignalProducer<Bool, ApiError>(value: !optographBox.model.shareAlias.isEmpty)
                .flatMap(.Latest) { alreadyPosted -> SignalProducer<Void, ApiError> in
                    if alreadyPosted {
                        return SignalProducer(value: ())
                    } else {
                        return ApiService<OptographApiModel>.post("optographs", parameters: postParameters)
                            .on(next: { [weak self] optograph in
                                self?.optographBox.insertOrUpdate { box in
                                    box.model.shareAlias = optograph.shareAlias
                                }
                            })
                            .map { _ in () }
                    }
                }
                .flatMap(.Latest) {
                    ApiService<EmptyResponse>.put("optographs/\(optograph.ID)", parameters: putParameters)
                        .on(failed: { [weak self] _ in
                            self?.optographBox.update { box in
                                box.model.isUploading = false
                            }
                        })
                }
                .on(next: { [weak self] optograph in
                    self?.optographBox.insertOrUpdate { box in
                        box.model.isOnServer = true
                    }
                })
                .startWithCompleted {
                    PipelineService.checkUploading()
                }
            
            
        } else {
            optographBox.insertOrUpdate { box in
                box.model.shouldBePublished = true
                box.model.isUploading = true
            }
            
            PipelineService.checkUploading()
        }
        
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
                let person = Models.persons[optograph.personID]!.model
                
                viewModel.bind(optographID)
                
                avatarImageView.kf_setImageWithURL(NSURL(string: ImageURL("persons/\(person.ID)/\(person.avatarAssetID).jpg", width: 47, height: 47))!)
                personNameView.text = person.displayName
                dateView.text = optograph.createdAt.longDescription
                textView.text = optograph.text
                
                if let locationID = optograph.locationID {
                    let location = Models.locations[locationID]!.model
                    locationTextView.text = "\(location.text), \(location.countryShort)"
                    personNameView.anchorInCorner(.TopLeft, xPad: 75, yPad: 17, width: 200, height: 18)
                    locationTextView.anchorInCorner(.TopLeft, xPad: 75, yPad: 37, width: 200, height: 13)
                    locationTextView.text = location.text
                } else {
                    personNameView.align(.ToTheRightCentered, relativeTo: avatarImageView, padding: 9.5, width: 100, height: 18)
                    locationTextView.text = ""
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
    private let uploadButtonView = BoundingButton()
    private let uploadTextView = BoundingLabel()
    private let uploadingView = UIActivityIndicatorView()
    private let dateView = UILabel()
    private let textView = BoundingLabel()
    
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
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(21)
        optionsButtonView.setTitle(String.iconWithName(.More), forState: .Normal)
        optionsButtonView.setTitleColor(UIColor(0xc6c6c6), forState: .Normal)
        optionsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "didTapOptions"))
        addSubview(optionsButtonView)
        
        locationTextView.font = UIFont.displayOfSize(11, withType: .Light)
        locationTextView.textColor = UIColor(0x3c3c3c)
        addSubview(locationTextView)
        
        likeButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleLike"))
        likeButtonView.setTitle(String.iconWithName(.Heart), forState: .Normal)
        likeButtonView.rac_hidden <~ viewModel.uploadStatus.producer.equalsTo(.Uploaded).map(negate)
        addSubview(likeButtonView)
        
        likeCountView.font = UIFont.displayOfSize(11, withType: .Semibold)
        likeCountView.textColor = .whiteColor()
        likeCountView.textAlignment = .Right
        likeCountView.rac_hidden <~ viewModel.uploadStatus.producer.equalsTo(.Uploaded).map(negate)
        addSubview(likeCountView)
        
        uploadButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "upload"))
        uploadButtonView.setTitle(String.iconWithName(.Upload), forState: .Normal)
        uploadButtonView.rac_hidden <~ viewModel.uploadStatus.producer.equalsTo(.Offline).map(negate)
        uploadButtonView.titleLabel!.font = UIFont.iconOfSize(24)
        addSubview(uploadButtonView)
        
        uploadTextView.font = UIFont.displayOfSize(11, withType: .Semibold)
        uploadTextView.text = "Upload"
        uploadTextView.textColor = .whiteColor()
        uploadTextView.textAlignment = .Right
        uploadTextView.userInteractionEnabled = true
        uploadTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "upload"))
        uploadTextView.rac_hidden <~ viewModel.uploadStatus.producer.equalsTo(.Offline).map(negate)
        addSubview(uploadTextView)
        
        uploadingView.hidesWhenStopped = true
        uploadingView.rac_animating <~ viewModel.uploadStatus.producer.equalsTo(.Uploading)
        addSubview(uploadingView)
        
        likeCountView.rac_text <~ viewModel.likeCount.producer.map { "\($0)" }
        
        viewModel.liked.producer.startWithNext { [weak self] liked in
            if let strongSelf = self {
//                if liked {
//                    strongSelf.likeButtonView.anchorInCorner(.BottomRight, xPad: 16, yPad: 130, width: 31, height: 28)
//                    strongSelf.likeButtonView.backgroundColor = .Accent
//                    strongSelf.likeButtonView.titleLabel?.font = UIFont.iconOfSize(15)
//                } else {
                    strongSelf.likeButtonView.anchorInCorner(.BottomRight, xPad: 16, yPad: 130, width: 24, height: 28)
                strongSelf.likeButtonView.setTitleColor(liked ? .Accent : .whiteColor(), forState: .Normal)
                    strongSelf.likeButtonView.titleLabel?.font = UIFont.iconOfSize(24)
//                }
                strongSelf.likeCountView.align(.ToTheLeftCentered, relativeTo: strongSelf.likeButtonView, padding: 10, width: 40, height: 13)
                strongSelf.uploadButtonView.anchorInCorner(.BottomRight, xPad: 16, yPad: 130, width: 24, height: 24)
                strongSelf.uploadTextView.align(.ToTheLeftCentered, relativeTo: strongSelf.uploadButtonView, padding: 8, width: 60, height: 13)
                strongSelf.uploadingView.anchorInCorner(.BottomRight, xPad: 16, yPad: 130, width: 24, height: 24)
            }
        }
        
        dateView.font = UIFont.displayOfSize(11, withType: .Regular)
        dateView.textColor = UIColor(0xbbbbbb)
        dateView.textAlignment = .Right
        addSubview(dateView)
        
        textView.font = UIFont.displayOfSize(14, withType: .Regular)
        textView.textColor = .whiteColor()
        textView.userInteractionEnabled = true
        textView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleText"))
        addSubview(textView)
        
        viewModel.textToggled.producer.startWithNext { [weak self] toggled in
            if let strongSelf = self, optograph = Models.optographs[strongSelf.optographID]?.model {
                let textHeight = calcTextHeight(optograph.text, withWidth: strongSelf.frame.width - 36 - 50, andFont: UIFont.displayOfSize(14, withType: .Regular))
                let displayedTextHeight = toggled && textHeight > 16 ? textHeight : 15
//                let bottomHeight: CGFloat = 50 + (optograph.text.isEmpty ? 0 : displayedTextHeight + 11)
                
//                UIView.setAnimationCurve(.EaseInOut)
//                UIView.animateWithDuration(0.3) {
//                    strongSelf.textView.frame = CGRect(x: 0, y: strongSelf.frame.height - bottomHeight, width: strongSelf.frame.width - 40, height: bottomHeight)
//                }
                
                strongSelf.textView.anchorInCorner(.BottomLeft, xPad: 16, yPad: 136, width: strongSelf.frame.width - 36 - 50, height: displayedTextHeight)
                
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
    
    dynamic private func toggleText() {
        viewModel.textToggled.value = !viewModel.textToggled.value
    }
    
    dynamic private func toggleLike() {
        if SessionService.isLoggedIn {
            viewModel.toggleLike()
        } else {
            parentViewController!.tabController!.hideUI()
            parentViewController!.tabController!.lockUI()
            
            let loginOverlayViewController = LoginOverlayViewController(
                title: "Login to like this moment",
                successCallback: {
                    self.viewModel.toggleLike()
                },
                cancelCallback: { true },
                alwaysCallback: {
                    self.parentViewController!.tabController!.unlockUI()
                    self.parentViewController!.tabController!.showUI()
                }
            )
            parentViewController!.presentViewController(loginOverlayViewController, animated: true, completion: nil)
        }
    }
    
    dynamic private func pushProfile() {
        navigationController?.pushViewController(ProfileCollectionViewController(personID: viewModel.optographBox.model.personID), animated: true)
    }
    
    dynamic private func pushSearch() {
//        navigationController?.pushViewController(SearchTableViewController(), animated: true)
    }
    
    dynamic private func upload() {
        if Reachability.connectedToNetwork() {
            viewModel.upload()
        } else {
            print("offline")
        }
    }
    
}

extension OverlayView: OptographOptions {
    
    dynamic func didTapOptions() {
        showOptions(viewModel.optographBox.model.ID, deleteCallback: deleteCallback)
    }
    
}
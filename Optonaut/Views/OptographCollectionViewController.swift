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


class OptographCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout ,TransparentNavbarWithStatusBar,TabControllerDelegate{
    
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
        
        collectionView!.pagingEnabled = false
        
        automaticallyAdjustsScrollViewInsets = false
        
        collectionView!.delaysContentTouches = false
        
        edgesForExtendedLayout = .None
        
        tabController!.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named:"profile_icn"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(OptographCollectionViewController.tapRightButton))
        
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
        
        overlayView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
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
            
            self?.collectionView!.scrollEnabled = !hidden
          
        }
        tabController!.delegate = self
    }
    
    func tapRightButton() {
        tabController!.rightButtonAction()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        uiHidden.value = false
        overlayView.alpha = 0
        viewModel.isActive.value = true
        
        tabController!.showUI()
        tabController!.enableScrollView()
        tabController!.enableNavBarGesture()
        
        CoreMotionRotationSource.Instance.start()
        
        view.bounds = UIScreen.mainScreen().bounds
        
        //RotationService.sharedInstance.rotationEnable()
        
//        if let indexPath = self.collectionView!.indexPathsForVisibleItems().first, cell = self.collectionView!.cellForItemAtIndexPath(indexPath) {
//            self.collectionView(self.collectionView!, willDisplayCell: cell, forItemAtIndexPath: indexPath)
//        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // TODO - remove as soon as correct disposal is implemented. 
        // imageCache.reset()
        
        //RotationService.sharedInstance.rotationDisable()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
        isVisible = true
        
//        if let rotationSignal = RotationService.sharedInstance.rotationSignal {
//            rotationSignal
//                .skipRepeats()
//                .filter([.LandscapeLeft, .LandscapeRight])
////                .takeWhile { [weak self] _ in self?.viewModel.viewIsActive.value ?? false }
//                .take(1)
//                .observeOn(UIScheduler())
//                .observeNext { [weak self] orientation in self?.pushViewer(orientation) }
//        }
        updateNavbarAppear()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        isVisible = false
        
        CoreMotionRotationSource.Instance.stop()
        
        viewModel.isActive.value = false
        tabController!.disableNavBarGesture()
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
        
        cell.navigationController = navigationController as? NavigationController
        
        let optographID = optographIDs[indexPath.row]
        
        cell.direction = optographDirections[optographID]!
        cell.willDisplay()
        cell.optoId = optographID
        
        let cubeImageCache = imageCache.get(indexPath.row, optographID: optographID, side: .Left)
        cell.setCubeImageCache(cubeImageCache)
        
        cell.id = indexPath.row
        cell.bindModel(optographID)
        
        if StitchingService.isStitching() {
            imageCache.resetExcept(indexPath.row)
        } else {
            for i in [-2, -1, 1, 2] where indexPath.row + i > 0 && indexPath.row + i < optographIDs.count {
                let id = optographIDs[indexPath.row + i]
                let cubeIndices = cell.getVisibleAndAdjacentPlaneIndices(optographDirections[id]!)
                imageCache.touch(indexPath.row + i, optographID: id, side: .Left, cubeIndices: cubeIndices)
            }
        }
        
        if indexPath.row > optographIDs.count - 5 {
            viewModel.loadMore()
        }
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        //return UIScreen.mainScreen().bounds.size
        
        return CGSizeMake(UIScreen.mainScreen().bounds.size.width, CGFloat((UIScreen.mainScreen().bounds.size.height/3)*2))
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let cell = cell as! OptographCollectionViewCell
        
        optographDirections[optographIDs[indexPath.row]] = cell.direction
        cell.didEndDisplay()
        
        imageCache.disable(indexPath.row)
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
                print(optographID)
            }
        }
    }
    private let avatarImageView = UIImageView()
    private let locationTextView = UILabel()
    private let uploadButtonView = BoundingButton()
    private let uploadTextView = BoundingLabel()
    private let uploadingView = UIActivityIndicatorView()
    private let dateView = UILabel()
    private let textView = BoundingLabel()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        uploadButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OverlayView.upload)))
        uploadButtonView.setTitle(String.iconWithName(.Upload), forState: .Normal)
        uploadButtonView.rac_hidden <~ viewModel.uploadStatus.producer.equalsTo(.Offline).map(negate)
        uploadButtonView.titleLabel!.font = UIFont.iconOfSize(24)
        addSubview(uploadButtonView)
        
        uploadTextView.font = UIFont.displayOfSize(11, withType: .Semibold)
        uploadTextView.text = "Upload"
        uploadTextView.textColor = .whiteColor()
        uploadTextView.textAlignment = .Right
        uploadTextView.userInteractionEnabled = true
        uploadTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OverlayView.upload)))
        uploadTextView.rac_hidden <~ viewModel.uploadStatus.producer.equalsTo(.Offline).map(negate)
        addSubview(uploadTextView)
        
        uploadingView.hidesWhenStopped = true
        uploadingView.rac_animating <~ viewModel.uploadStatus.producer.equalsTo(.Uploading)
        addSubview(uploadingView)
        
        dateView.font = UIFont.displayOfSize(11, withType: .Regular)
        dateView.textColor = UIColor(0xbbbbbb)
        dateView.textAlignment = .Right
        addSubview(dateView)
        
        textView.font = UIFont.displayOfSize(14, withType: .Regular)
        textView.textColor = .whiteColor()
        textView.userInteractionEnabled = true
        textView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OverlayView.toggleText)))
        addSubview(textView)
        
        viewModel.textToggled.producer.startWithNext { [weak self] toggled in
            if let strongSelf = self, optograph = Models.optographs[strongSelf.optographID]?.model {
                let textHeight = calcTextHeight(optograph.text, withWidth: strongSelf.frame.width - 36 - 50, andFont: UIFont.displayOfSize(14, withType: .Regular))
                let displayedTextHeight = toggled && textHeight > 16 ? textHeight : 15
                
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
            
//            let loginOverlayViewController = LoginOverlayViewController(
//                title: "Login to like this moment",
//                successCallback: {
//                    self.viewModel.toggleLike()
//                },
//                cancelCallback: { true },
//                alwaysCallback: {
//                }
//            )
//            parentViewController!.presentViewController(loginOverlayViewController, animated: true, completion: nil)
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
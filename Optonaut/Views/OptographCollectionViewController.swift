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
import SwiftyUserDefaults

typealias Direction = (phi: Float, theta: Float)

protocol OptographCollectionViewModel {
    var isActive: MutableProperty<Bool> { get }
    var results: MutableProperty<TableViewResults<Optograph>> { get }
    func refresh()
    func loadMore()
}


class OptographCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout ,TransparentNavbarWithStatusBar,TabControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    private let queue = dispatch_queue_create("collection_view", DISPATCH_QUEUE_SERIAL)
    
    private let viewModel: OptographCollectionViewModel
    private let imageCache: CollectionImageCache
    private let overlayDebouncer: Debouncer
    
    private var optographIDs: [UUID] = []
    private var optographDirections: [UUID: Direction] = [:]
    
    private let refreshControl = UIRefreshControl()
    
    private let uiHidden = MutableProperty<Bool>(false)
    
    private var overlayIsAnimating = false
    
    private var isVisible = false
    
    private var tabView = TabView()
    
    let isThetaImage = MutableProperty<Bool>(false)
    
    var imageView: UIImageView!
    var imagePicker = UIImagePickerController()
    
    let shareData = ShareData.sharedInstance
    
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
        
        
        var image = UIImage(named: "profile_page_icn")
        image = image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(OptographCollectionViewController.tapRightButton))
        
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
        
        uiHidden.producer.startWithNext { [weak self] hidden in
            self?.navigationController?.setNavigationBarHidden(hidden, animated: false)
            
            self?.collectionView!.scrollEnabled = !hidden
          
        }
        tabController!.delegate = self
        tabView.frame = CGRect(x: 0,y: view.frame.height - 126,width: view.frame.width,height: 126)
        view.addSubview(tabView)
        
        
        tabView.cameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapCameraButton)))
        tabView.cameraButton.addTarget(self, action: #selector(touchStartCameraButton), forControlEvents: [.TouchDown])
        tabView.cameraButton.addTarget(self, action: #selector(touchEndCameraButton), forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
        
        tabView.leftButton.addTarget(self, action: #selector(tapLeftButton), forControlEvents: [.TouchDown])
        
        tabView.rightButton.addTarget(self, action: #selector(tapRightButtonTab), forControlEvents: [.TouchUpInside])
        
        PipelineService.stitchingStatus.producer
            .observeOnMain()
            .startWithNext { [weak self] status in
                switch status {
                case .Uninitialized:
                    self?.tabView.cameraButton.loading = true
                    print("uninitialized")
                case .Idle:
                    self?.tabView.cameraButton.progress = nil
                    if self?.tabView.cameraButton.progressLocked == false {
                        self?.tabView.cameraButton.icon = UIImage(named:"camera_icn")!
                        self?.tabView.rightButton.loading = false
                    }
                    print("Idle")
                case let .Stitching(progress):
                    self?.tabView.cameraButton.progress = CGFloat(progress)
                    print("Stitching")
                case .StitchingFinished(_):
                    self?.tabView.cameraButton.progress = nil
                    print("StitchingFinished")
                }
        }
        updateTabs()
        //initNotificationIndicator()
        imagePicker.delegate = self
        
        isThetaImage.producer
            .filter(isTrue)
            .startWithNext{ _ in
                let alert = UIAlertController(title: "Ooops!", message: "Not a Theta Image, Please choose another photo", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{ _ in
                    self.isThetaImage.value = false
                }))
                self.presentViewController(alert, animated: true, completion: nil)
        }
        
        PipelineService.checkStitching()
        PipelineService.checkUploading()
        
    }
    func openGallary() {
        
//        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
//        imagePicker.navigationBar.translucent = false
//        imagePicker.navigationBar.barTintColor = UIColor(hex:0x343434)
//        imagePicker.navigationBar.setTitleVerticalPositionAdjustment(0, forBarMetrics: .Default)
//        imagePicker.navigationBar.titleTextAttributes = [
//            NSFontAttributeName: UIFont.displayOfSize(15, withType: .Semibold),
//            NSForegroundColorAttributeName: UIColor.whiteColor(),
//        ]
//        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
//        imagePicker.setNavigationBarHidden(false, animated: false)
//        imagePicker.interactivePopGestureRecognizer?.enabled = false
//        
//        self.presentViewController(imagePicker, animated: true, completion: nil)
        
        let imagePickVC = ViewController()
        
        imagePickVC.imagePicked.producer.startWithNext{ image in
            if image != nil {
                self.uploadTheta(image!)
            }
        }
        
        self.presentViewController(imagePickVC, animated: true, completion: nil)
    }
    
    func uploadTheta(thetaImage:UIImage) {
        
        Defaults[.SessionUploadMode] = "theta"
        
        let createOptographViewController = SaveThetaViewController(thetaImage:thetaImage)
        
        createOptographViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(createOptographViewController, animated: false)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if pickedImage.size.height == 2688 && pickedImage.size.width == 5376 {
                uploadTheta(pickedImage)
            } else {
                isThetaImage.value = false
            }
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tapCameraButton() {
        
        switch PipelineService.stitchingStatus.value {
        case .Idle:
            self.tabController?.centerViewController.cleanup()
            self.tabController?.rightViewController.cleanup()
            self.tabController?.leftViewController.cleanup()
            
            Defaults[.SessionUploadMode] = "opto"
            navigationController?.pushViewController(CameraViewController(), animated: false)
            
        case .Stitching(_):
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last image has finished rendering.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            tabController?.centerViewController.presentViewController(alert, animated: true, completion: nil)
        case let .StitchingFinished(optographID):
            scrollToOptographFeed(optographID)
            PipelineService.stitchingStatus.value = .Idle
        case .Uninitialized: ()
        }
    }
    
    func scrollToOptographFeed(optographID: UUID) {
        let row = optographIDs.indexOf(optographID)
        collectionView!.scrollToItemAtIndexPath(NSIndexPath(forRow: row!, inSection: 0), atScrollPosition: .Top, animated: true)
    }
    
    func touchStartCameraButton() {
        print("")
    }
    func touchEndCameraButton() {
        print("")
    }
    func tapLeftButton() {
        if Reachability.connectedToNetwork() {
            openGallary()
        } else {
            let alert = UIAlertController(title: "Ooops!", message: "Please check network connection!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    func tapRightButtonTab() {
        tabController!.tapNavBarTitleForFeedClass()
    }
    
    func tapRightButton() {
        tabController!.rightButtonAction()
    }
    
    func showUI() {
        tabView.hidden = false
    }
    
    func hideUI() {
        tabView.hidden = true
    }
    
    private func initNotificationIndicator() {
        let circle = UILabel()
        circle.frame = CGRect(x: tabView.rightButton.frame.origin.x + 25, y: tabView.rightButton.frame.origin.y - 3, width: 16, height: 16)
        circle.backgroundColor = .Accent
        circle.font = UIFont.displayOfSize(10, withType: .Regular)
        circle.textAlignment = .Center
        circle.textColor = .whiteColor()
        circle.layer.cornerRadius = 8
        circle.clipsToBounds = true
        circle.hidden = true
        tabView.addSubview(circle)
        
        ActivitiesService.unreadCount.producer.startWithNext { count in
            let hidden = count <= 0
            circle.hidden = hidden
            circle.text = "\(count)"
        }
    }
    
    func updateTabs() {
        tabView.leftButton.icon = UIImage(named:"photo_library_icn")!
        tabView.rightButton.icon = UIImage(named:"settings_icn")!
        tabView.cameraButton.icon = UIImage(named:"camera_icn")!
        tabView.bottomGradientOffset.value = 126
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        uiHidden.value = false
        viewModel.isActive.value = true
        
        showUI()
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
        
        cell.bindModel(optographID)
        cell.direction = optographDirections[optographID]!
        cell.willDisplay()
        cell.optoId = optographID
        
        let cubeImageCache = imageCache.get(indexPath.row, optographID: optographID, side: .Left)
        cell.setCubeImageCache(cubeImageCache)
        
        cell.id = indexPath.row
        cell.swipeView = tabController!.scrollView
        
        cell.isShareOpen.producer
            .startWithNext{ val in
                if val{
                    print("optographid =",optographID)
                   // cell.setRotation(true)
                    self.shareData.optographId.value = optographID
                } else {
                    print("close")
                    //cell.setRotation(false)
                }
            }
        
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
    
//    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
//        print("index willdisplaycell \(indexPath.row)")
//        let cell:OptographCollectionViewCell = cell as! OptographCollectionViewCell
//        
//        print(cell.frame.origin.y)
//        let cellPosition = cell.frame.origin.y - collectionView.contentOffset.y
//        
//        if (cellPosition > 100 && cellPosition < 150) {
//            print("pumasok sa if \(indexPath.row)")
//            cell.setRotation(true)
//        } else if (cellPosition < 0) {
//            print("pumasok sa else if \(indexPath.row)")
//            cell.setRotation(true)
//        } else {
//             print("pumasok sa else \(indexPath.row)")
//            cell.setRotation(false)
//        }
//    }
    
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
       
        let cells = collectionView!.visibleCells() as! Array<OptographCollectionViewCell>
        for cell in cells {
            cell.setRotation(false)
        }

        let superCenter = CGPointMake(CGRectGetMidX(collectionView!.bounds), CGRectGetMidY(collectionView!.bounds));
        
        let visibleIndexPath: NSIndexPath = collectionView!.indexPathForItemAtPoint(superCenter)!
        
        
        let cell = collectionView?.cellForItemAtIndexPath(visibleIndexPath) as! OptographCollectionViewCell
        
        cell.setRotation(true)

    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {

    
        let cells = collectionView!.visibleCells() as! Array<OptographCollectionViewCell>
        for cell in cells {
            cell.setRotation(false)
        }

        let superCenter = CGPointMake(CGRectGetMidX(collectionView!.bounds), CGRectGetMidY(collectionView!.bounds));
     
        let visibleIndexPath: NSIndexPath = collectionView!.indexPathForItemAtPoint(superCenter)!
        
        let cell = collectionView?.cellForItemAtIndexPath(visibleIndexPath) as! OptographCollectionViewCell
    
        cell.setRotation(true)
        
    }
    
 
    
    override func cleanup() {
        for cell in collectionView!.visibleCells().map({ $0 as! OptographCollectionViewCell }) {
            cell.forgetTextures()
            cell.setRotation(false)
        }
        
        imageCache.reset()
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

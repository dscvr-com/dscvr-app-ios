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
//import FillableLoaders

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
    
    private let fileManager = NSFileManager.defaultManager()
    
    let isThetaImage = MutableProperty<Bool>(false)
    
    var imageView: UIImageView!
    var imagePicker = UIImagePickerController()
    
    let shareData = ShareData.sharedInstance
    
    //var loader: FillableLoader = FillableLoader()
    
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
        
        var leftButton = UIImage(named: "search_icn")
        leftButton = leftButton?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftButton, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(OptographCollectionViewController.tapLeftBarButton))
        
        
        var image = UIImage(named: "profile_page_icn")
        image = image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(OptographCollectionViewController.tapRightButton))
        
        viewModel.results.producer
            .filter {return $0.changed }
            .retryUntil(0.1, onScheduler: QueueScheduler(queue: queue)) { [weak self] in self?.collectionView!.decelerating == false && self?.collectionView!.dragging == false }
            .delayAllUntil(viewModel.isActive.producer)
            .observeOnMain()
            .on(next: { [weak self] results in
                print("reload data =======")
                
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
                                print("need to delete>>",results.delete)
                                print("need to update>>",results.update)
                                print("need to insert>>",results.insert)
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
                        strongSelf.collectionView!.reloadData()
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
        
//        loader = WavesLoader.showLoaderWithPath(self.path(), onView:view)
//        loader.progressBased = true
//        loader.loaderColor = UIColor(0xffbc00)
//        loader.frame = CGRect(x: 50,y: 200 ,width: 0,height: 0)
        
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
                    //self!.loader.progress = CGFloat(progress)
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
    func path() -> CGPath{
        return SamplePaths.cameraPath()
    }
    func openGallary() {
        if Defaults[.SessionEliteUser] {
            let imagePickVC = ViewController()
            
            imagePickVC.imagePicked.producer.startWithNext{ image in
                if image != nil {
                    self.uploadTheta(image!)
                }
            }
            
            self.presentViewController(imagePickVC, animated: true, completion: nil)
        } else{
            //self.presentViewController(InvitationViewController(), animated: true, completion: nil)
            self.tapRightButton()
        }
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
            
            if Defaults[.SessionEliteUser] {
                navigationController?.pushViewController(CameraViewController(), animated: false)
            } else{
                //self.presentViewController(InvitationViewController(), animated: true, completion: nil)
                self.tapRightButton()
            }
            
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
    
    func tapLeftBarButton() {
        self.navigationController?.pushViewController(SearchViewController(), animated: true)
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
        
        viewModel.refresh()
        viewModel.isActive.value = true
        
        showUI()
        tabController!.enableScrollView()
        tabController!.enableNavBarGesture()
        
        view.bounds = UIScreen.mainScreen().bounds
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
        updateNavbarAppear()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        isVisible = false
        
        //CoreMotionRotationSource.Instance.stop()
        
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
        print("count ng mga optograph",optographIDs.count)
        return optographIDs.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let optographID = optographIDs[indexPath.row]
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! OptographCollectionViewCell
        
        cell.navigationController = navigationController as? NavigationController
        cell.bindModel(optographID)
        cell.swipeView = tabController!.scrollView
        cell.collectionView = collectionView
        cell.isShareOpen.producer
            .startWithNext{ val in
                if val{
                    self.shareData.optographId.value = optographID
                    self.shareData.isSharePageOpen.value = true
                }
        }
        
        if indexPath.row > optographIDs.count - 3 {
            viewModel.loadMore()
        }
//        if arrayOfDir.indices.contains(indexPath.row) {
//            if arrayOfDir[indexPath.row] != "" {
//                cell.video = AVPlayer(URL: NSURL(fileURLWithPath: arrayOfDir[indexPath.row]))
//            } else {
//                cell.video = nil
//            }
//        } else {
//            cell.video = nil
//        }
    
        return cell
    }
//    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
//        
//        let optographID = optographIDs[indexPath.row]
//        
//        let filename = "http://s3-ap-southeast-1.amazonaws.com/resources.staging-iam360.io/textures/\(optographID)/pan.mp4"
//        
//        let returnData = imageCache.insertMp4IntoCache(filename,optographId:optographID)
//        
//        arrayOfDir.insert(returnData, atIndex: indexPath.row)
//        
//    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let detailsViewController = DetailsTableViewController(optographId:optographIDs[indexPath.row])
        detailsViewController.cellIndexpath = indexPath.item
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    //size
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return CGSizeMake(UIScreen.mainScreen().bounds.size.width, CGFloat((UIScreen.mainScreen().bounds.size.height/5)*2))
    }
    
    
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
        let cells = collectionView!.visibleCells() as! Array<OptographCollectionViewCell>
        for cell in cells {
            cell.setRotation(false)
        }
        
        let superCenter = CGPointMake(CGRectGetMidX(collectionView!.bounds), CGRectGetMidY(collectionView!.bounds))
        if let visibleIndexPath: NSIndexPath = collectionView!.indexPathForItemAtPoint(superCenter){
            if let cell:OptographCollectionViewCell = collectionView?.cellForItemAtIndexPath(visibleIndexPath) as? OptographCollectionViewCell {
            
                cell.setRotation(true)
            }
        }
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        
        let cells = collectionView!.visibleCells() as! Array<OptographCollectionViewCell>
        for cell in cells {
            cell.setRotation(false)
        }
        
        let superCenter = CGPointMake(CGRectGetMidX(collectionView!.bounds), CGRectGetMidY(collectionView!.bounds))
        if let visibleIndexPath: NSIndexPath = collectionView!.indexPathForItemAtPoint(superCenter) {
            if let cell:OptographCollectionViewCell = collectionView?.cellForItemAtIndexPath(visibleIndexPath) as? OptographCollectionViewCell {
                cell.setRotation(true)
            }
        }
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
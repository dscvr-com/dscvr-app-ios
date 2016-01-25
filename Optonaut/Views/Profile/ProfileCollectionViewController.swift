//
//  ProfileCollectionViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 23/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SpriteKit

class ProfileCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, RedNavbar {
    
    private let queue = dispatch_queue_create("profile_collection_view", DISPATCH_QUEUE_SERIAL)
    
    private let profileViewModel: ProfileViewModel
    private let collectionViewModel: OptographsViewModel
    private var optographIDs: [UUID] = []
    private let imageCache: CollectionImageCache
    
    private let editOverlayView = UIView()
    
    private var originalBackButton: UIBarButtonItem?
    private let leftBarButton = UILabel()
    private let rightBarButton = UILabel()
    
    init(personID: UUID) {
        profileViewModel = ProfileViewModel(personID: personID)
        collectionViewModel = OptographsViewModel(personID: personID)
        
        let textureSize = (getTextureWidth(UIScreen.mainScreen().bounds.width, hfov: HorizontalFieldOfView) - 4) / 3
        imageCache = CollectionImageCache(textureSize: textureSize)
        
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileViewModel.userName.producer.startWithNext { [weak self] userName in
            self?.title = userName.uppercaseString
        }
        
        originalBackButton = navigationItem.leftBarButtonItem
        
        leftBarButton.frame = CGRect(x: 0, y: -2, width: 21, height: 21)
        leftBarButton.text = String.iconWithName(.Cancel)
        leftBarButton.textColor = .whiteColor()
        leftBarButton.font = UIFont.iconOfSize(19)
        leftBarButton.userInteractionEnabled = true
        leftBarButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapLeftBarButton"))
        let barButtonItem = UIBarButtonItem(customView: leftBarButton)
        
        profileViewModel.isEditing.producer.startWithNext { [weak self] isEditing in
            self?.navigationItem.leftBarButtonItem = isEditing ? barButtonItem : self?.originalBackButton
        }
        
        rightBarButton.frame = CGRect(x: 0, y: -2, width: 21, height: 21)
        rightBarButton.rac_text <~ profileViewModel.isEditing.producer.mapToTuple(String.iconWithName(.Check), String.iconWithName(.More))
        rightBarButton.textColor = .whiteColor()
        rightBarButton.font = UIFont.iconOfSize(21)
        rightBarButton.userInteractionEnabled = true
        rightBarButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapRightBarButton"))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)
        
        editOverlayView.backgroundColor = UIColor.blackColor().alpha(0.6)
        editOverlayView.rac_hidden <~ profileViewModel.isEditing.producer.map(negate)
        view.addSubview(editOverlayView)
        
        profileViewModel.isEditing.producer.skip(1).startWithNext { [weak self] isEditing in
            if let strongSelf = self {
                
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                strongSelf.collectionView!.performBatchUpdates({
                    strongSelf.collectionView!.reloadItemsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)])
                }, completion: { _ in
                    CATransaction.commit()
                })
                
                if isEditing {
                    let collectionViewSize = strongSelf.collectionView!.frame.size
                    let textHeight = calcTextHeight(strongSelf.profileViewModel.text.value, withWidth: collectionViewSize.width - 28, andFont: UIFont.displayOfSize(12, withType: .Regular))
                    let headerHeight = 248 + textHeight
                    strongSelf.editOverlayView.frame = CGRect(x: 0, y: headerHeight, width: collectionViewSize.width, height: collectionViewSize.height - headerHeight)
                    
                    strongSelf.collectionView!.contentOffset = CGPointZero
                }
                
                strongSelf.collectionView!.scrollEnabled = !isEditing
            }
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        collectionView!.registerClass(ProfileHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "top-cell")
        collectionView!.registerClass(TileCollectionViewCell.self, forCellWithReuseIdentifier: "tile-cell")
        
        collectionView!.backgroundColor = .whiteColor()
        
        collectionView!.delegate = self
        
//        collectionView!.pagingEnabled = true
        
//        automaticallyAdjustsScrollViewInsets = false
        
        collectionView!.delaysContentTouches = false
        
//        edgesForExtendedLayout = .None
        
        collectionViewModel.results.producer
//            .retryUntil(0.1, onScheduler: QueueScheduler(queue: queue)) { [weak self] in self?.collectionView!.decelerating == false && self?.collectionView!.dragging == false }
            .delayAllUntil(collectionViewModel.isActive.producer)
            .observeOnMain()
            .on(next: { [weak self] results in
                if let strongSelf = self {
//                    let visibleOptographID: UUID? = strongSelf.optographIDs.isEmpty ? nil : strongSelf.optographIDs[strongSelf.collectionView!.indexPathsForVisibleItems().first!.row]
                    strongSelf.optographIDs = results.models.map { $0.ID }
                    
//                    CATransaction.begin()
//                    CATransaction.setDisableActions(true)
                        strongSelf.collectionView!.performBatchUpdates({
//                            strongSelf.imageCache.delete(results.delete)
//                            strongSelf.imageCache.insert(results.insert)
                            strongSelf.collectionView!.deleteItemsAtIndexPaths(results.delete.map { NSIndexPath(forRow: $0 + 1, inSection: 0) })
                            strongSelf.collectionView!.reloadItemsAtIndexPaths(results.update.map { NSIndexPath(forRow: $0 + 1, inSection: 0) })
                            strongSelf.collectionView!.insertItemsAtIndexPaths(results.insert.map { NSIndexPath(forRow: $0 + 1, inSection: 0) })
                        }, completion: { _ in
//                            if (!results.delete.isEmpty || !results.insert.isEmpty) && !strongSelf.refreshControl.refreshing {
//                                // preserves scroll position
//                                if let visibleOptographID = visibleOptographID, visibleRow = strongSelf.optographIDs.indexOf({ $0 == visibleOptographID }) {
//                                    strongSelf.collectionView!.contentOffset = CGPoint(x: 0, y: CGFloat(visibleRow) * strongSelf.view.frame.height)
//                                }
//                            }
//                            strongSelf.refreshControl.endRefreshing()
//                            CATransaction.commit()
                        })
                }
            })
            .start()
        
        collectionViewModel.isActive.producer
            .skip(1)
            .map(negate)
            .filter(identity)
            .startWithNext { [weak self] _ in
                self?.imageCache.reset()
            }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        CoreMotionRotationSource.Instance.start()
        
        collectionViewModel.refreshNotification.notify(())
        
        collectionViewModel.isActive.value = true
        
//        view.bounds = UIScreen.mainScreen().bounds
        
//        RotationService.sharedInstance.rotationEnable()
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
//        RotationService.sharedInstance.rotationDisable()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
        
        tabController!.delegate = self
        
        updateTabs()
        
        tabController!.showUI()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        collectionViewModel.isActive.value = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        view.frame = UIScreen.mainScreen().bounds
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return optographIDs.count + 1
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("top-cell", forIndexPath: indexPath) as! ProfileHeaderCollectionViewCell
            
            cell.bindViewModel(profileViewModel)
            cell.navigationController = navigationController as? NavigationController
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("tile-cell", forIndexPath: indexPath) as! TileCollectionViewCell
            
            let optographID = optographIDs[indexPath.row - 1]
            cell.bind(optographID)
            
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.row == 0 {
            let textHeight = calcTextHeight(profileViewModel.text.value, withWidth: collectionView.frame.width - 28, andFont: UIFont.displayOfSize(12, withType: .Regular))
            return CGSize(width: collectionView.frame.width, height: 248 + textHeight)
        } else {
            let width = (collectionView.frame.width - 4) / 3 - 0.000001
            return CGSize(width: width, height: width)
        }
    }
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row == 0 {
            
        } else {
            let cell = cell as! TileCollectionViewCell
            let optographID = optographIDs[indexPath.row - 1]
            
            let imageCallback = { [weak self] (image: SKTexture, index: CubeImageCache.Index) in
                if self?.collectionView?.indexPathsForVisibleItems().contains(indexPath) == true {
                    cell.setImage(image, forIndex: index)
                }
            }
            
            dispatch_async(queue) { [weak self] in
                let defaultIndices = [
                    CubeImageCache.Index(face: 0, x: 0, y: 0, d: 1),
                    CubeImageCache.Index(face: 1, x: 0, y: 0, d: 1),
                    CubeImageCache.Index(face: 2, x: 0, y: 0, d: 1),
                    CubeImageCache.Index(face: 3, x: 0, y: 0, d: 1),
                    CubeImageCache.Index(face: 4, x: 0, y: 0, d: 1),
                    CubeImageCache.Index(face: 5, x: 0, y: 0, d: 1),
                ]
                self?.imageCache.get(indexPath.row, optographID: optographID, side: .Left, cubeIndices: defaultIndices, callback: imageCallback)
            }
        }
        
//        guard let cell = cell as? CollectionViewCell else {
//            return
//        }
//        
//        let optographID = optographIDs[indexPath.row]
//        let optograph = Models.optographs[optographID]!.model
//        
//        cell.willDisplay((phi: Float(optograph.directionPhi), theta: Float(optograph.directionTheta)))
//        
//        print("will disp \(indexPath.row)")
//        
//        let imageCallback = { [weak self] (image: SKTexture, index: CubeImageCache.Index) in
//            if self?.collectionView?.indexPathsForVisibleItems().contains(indexPath) == true {
//                cell.setImage(image, forIndex: index)
//            }
//        }
//        
//        dispatch_async(queue) { [weak self] in
//            let defaultIndices = [
//                CubeImageCache.Index(face: 0, x: 0, y: 0, d: 1),
//                CubeImageCache.Index(face: 1, x: 0, y: 0, d: 1),
//                CubeImageCache.Index(face: 2, x: 0, y: 0, d: 1),
//                CubeImageCache.Index(face: 3, x: 0, y: 0, d: 1),
//                CubeImageCache.Index(face: 4, x: 0, y: 0, d: 1),
//                CubeImageCache.Index(face: 5, x: 0, y: 0, d: 1),
//            ]
//            self?.imageCache.get(indexPath.row, optographID: optographID, side: .Left, cubeIndices: defaultIndices, callback: imageCallback)
//        }
//        
//        if overlayView.optographID == nil {
//            overlayView.optographID = optographID
//        }
//        
////        cacheDebouncerTouch.debounce { [weak self] in
////            self?.imageCache.touch(indexPath.row)
////        }
//        
        
        if indexPath.row % 3 == 1 && indexPath.row > optographIDs.count - 7 {
            collectionViewModel.loadMoreNotification.notify(())
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
//        (cell as! CollectionViewCell).didEndDisplay()
    }
    
    dynamic private func tapLeftBarButton() {
    }
    
    dynamic private func tapRightBarButton() {
        if profileViewModel.isEditing.value {
            profileViewModel.isEditing.value = false
        } else {
            let settingsSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            if profileViewModel.isMe {
                settingsSheet.addAction(UIAlertAction(title: "Sign out", style: .Destructive, handler: { _ in
                    SessionService.logout()
                }))
            } else {
                settingsSheet.addAction(UIAlertAction(title: "Report user", style: .Destructive, handler: { _ in
                    let confirmAlert = UIAlertController(title: "Are you sure?", message: "This action will message one of the moderators.", preferredStyle: .Alert)
                    confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
                    confirmAlert.addAction(UIAlertAction(title: "Report", style: .Destructive, handler: { _ in
                        //                    self.viewModel.person.report().start()
                    }))
                    self.navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
                }))
            }
            
            settingsSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
            
            navigationController?.presentViewController(settingsSheet, animated: true, completion: nil)
        }
    }
    
}

// MARK: - UITabBarControllerDelegate
extension ProfileCollectionViewController: DefaultTabControllerDelegate {
    
    func jumpToTop() {
        collectionViewModel.refreshNotification.notify(())
        collectionView!.setContentOffset(CGPointZero, animated: true)
    }
    
}

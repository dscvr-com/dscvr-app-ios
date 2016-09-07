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
import SwiftyUserDefaults

class ProfileCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout,TransparentNavbarWithStatusBar ,TabControllerDelegate{
    
    private let queue = dispatch_queue_create("profile_collection_view", DISPATCH_QUEUE_SERIAL)
    
    private var profileViewModel: ProfileViewModel
    private var collectionViewModel: ProfileOptographsViewModel
    private var optographIDs: [UUID] = []
    //private var optographIDsNotUploaded = MutableProperty<[UUID]>([])
    private var optographIDsNotUploaded :[UUID] = []
    
    weak var parentVC: UIViewController?
    
    private let editOverlayView = UIView()
    
    private let leftBarButton = UILabel()
    private let rightBarButton = UILabel()
    
    private var barButtonItem = UIBarButtonItem()
    private var originalBackButton: UIBarButtonItem?
    let headerView = UIView()
    var isProfileVisit:Bool = false
    var isFollowClicked:Bool = false
    var isNotifClicked:Bool = true
    var fromLoginPage:Bool = false
    var finishReloadingCollectionView = MutableProperty<Bool>(false)
    
    init(personID: UUID) {
        
        collectionViewModel = ProfileOptographsViewModel(personID: personID)
        profileViewModel = ProfileViewModel(personID: personID)
        
        super.init(collectionViewLayout: UICollectionViewLeftAlignedLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        title = "My Profile"
        
        headerView.frame = CGRect(x: 0,y: 0,width: view.frame.width ,height: 50)
        headerView.backgroundColor = UIColor(hex:0x3E3D3D)
        headerView.hidden = true
        view.addSubview(headerView)
        let texttext = UILabel()
        texttext.frame = CGRect(x: view.frame.width / 2 - (150/2),y: 15,width: 150,height: 20)
        texttext.text = "Images"
        texttext.textAlignment = .Center
        texttext.textColor = UIColor.whiteColor()
        headerView.addSubview(texttext)
        
        
        originalBackButton = navigationItem.leftBarButtonItem
        
        tabController?.delegate = self
        
        if !isProfileVisit {
            //var image = UIImage(named: "logo_small")
            var image = UIImage(named:"iam360_navTitle")
            image = image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
            originalBackButton = UIBarButtonItem(image: image, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.goToFeeds))
        }
        
        leftBarButton.frame = CGRect(x: 0, y: -2, width: 60, height: 21)
        leftBarButton.text = "Cancel"
        leftBarButton.textColor = .blackColor()
        leftBarButton.font = UIFont.iconOfSize(15)
        leftBarButton.userInteractionEnabled = true
        leftBarButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileCollectionViewController.tapLeftBarButton)))
        barButtonItem = UIBarButtonItem(customView: leftBarButton)
        
        profileViewModel.isEditing.producer.startWithNext { [weak self] isEditing in
            
            self?.navigationItem.leftBarButtonItem = isEditing ? self!.barButtonItem : self?.originalBackButton
            isEditing ? self?.tabController!.disableScrollView() : self?.tabController!.enableScrollView()
        }
        
        profileViewModel.followTabTouched.producer.startWithNext { [weak self] isFollowTabTap in
            if isFollowTabTap {
                self!.isFollowClicked = true
                self!.isNotifClicked = false
            } else {
                self!.isFollowClicked = false
                self!.isNotifClicked = false
            }
            self!.collectionView?.reloadData()
            self!.collectionViewModel.refreshNotification.notify(())
            
//            if self?.optographIDsNotUploaded.count != 0 {
//                let indexPath = NSIndexPath(forRow: 1, inSection: 0)
//                self?.collectionView?.reloadItemsAtIndexPaths([indexPath])
//            }
        }
        
        profileViewModel.notifTabTouched.producer.startWithNext { [weak self] isNotifTabTap in
            if isNotifTabTap {
                self!.isNotifClicked = true
                self!.isFollowClicked = false
                self!.readAllNotification()
                    .on(
                        completed: { [weak self] in
                            UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                            ActivitiesService.unreadCount.value = 0
                        }
                    )
                    .start()
                
                self!.collectionView?.reloadData()
            }
        }
        
        rightBarButton.frame = CGRect(x: 0, y: -2, width: 20, height: 21)
        rightBarButton.rac_text <~ profileViewModel.isEditing.producer.mapToTuple("Save", String.iconWithName(.More))
        rightBarButton.font = UIFont.iconOfSize(15)
        rightBarButton.userInteractionEnabled = true
        rightBarButton.textColor = UIColor(hex:0xFF5E00)
        rightBarButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileCollectionViewController.tapRightBarButton)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)
        
        editOverlayView.backgroundColor = UIColor.blackColor().alpha(0.6)
        editOverlayView.rac_hidden <~ profileViewModel.isEditing.producer.map(negate)
        view.addSubview(editOverlayView)
        _ = self.navigationController?.navigationBar.frame.height
        
        profileViewModel.isEditing.producer.skip(1).startWithNext { [weak self] isEditing in
            if let strongSelf = self {
                
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                strongSelf.collectionView!.performBatchUpdates(nil, completion: { _ in CATransaction.commit() })
                
                if isEditing {
                    self?.rightBarButton.frame = CGRect(x: 0, y: -2, width: 40, height: 21)
                    let collectionViewSize = strongSelf.collectionView!.frame.size
                    //let textHeight = calcTextHeight(strongSelf.profileViewModel.text.value, withWidth: collectionViewSize.width - 28, andFont: UIFont.fontDisplay(12, withType: .Regular))
                    
                    let cellSize = strongSelf.collectionView(strongSelf.collectionView!, layout: strongSelf.collectionView!.collectionViewLayout, sizeForItemAtIndexPath: NSIndexPath(forItem: 0, inSection: 0))
                    
                    //let headerHeight = strongSelf.view.frame.height * 0.5 + textHeight
                    
                    let headerHeight = cellSize.height + 20
                    
                    strongSelf.editOverlayView.frame = CGRect(x: 0, y: headerHeight, width: collectionViewSize.width, height: collectionViewSize.height - headerHeight)
                    
                    strongSelf.collectionView!.contentOffset = CGPoint(x: 0,y:-44)
                    strongSelf.title = "Edit My Profile"
                } else {
                    self?.rightBarButton.frame = CGRect(x: 0, y: -2, width: 20, height: 21)
                    strongSelf.title = "My Profile"
                    
                }
                
                strongSelf.collectionView!.scrollEnabled = !isEditing
            }
        }
        
        // Register cell classes
        collectionView!.registerClass(ProfileHeaderCollectionViewCell.self, forCellWithReuseIdentifier: "top-cell")
        collectionView!.registerClass(ProfileTileCollectionViewCell.self, forCellWithReuseIdentifier: "tile-cell")
        collectionView!.registerClass(ProfileUploadCollectionViewCell.self, forCellWithReuseIdentifier: "upload-cell")
        collectionView!.registerClass(ProfileFollowersViewCell.self, forCellWithReuseIdentifier: "followers-cell")
        collectionView!.registerClass(NotificationTableViewCell.self, forCellWithReuseIdentifier: "notification-cell")
        
        collectionView!.backgroundColor = UIColor(hex:0xf7f7f7)
        
        collectionView!.alwaysBounceVertical = true
        
        collectionView!.delegate = self
        
        
        collectionView!.delaysContentTouches = false
        
        collectionViewModel.results.producer
            .filter{$0.changed}
            .delayAllUntil(collectionViewModel.isActive.producer)
            .observeOnMain()
            .on(next: { [weak self] results in
                
                if let strongSelf = self {
                    strongSelf.optographIDsNotUploaded = results.models
                        .filter{ !$0.isPublished && !$0.isUploading}
                        .map{$0.ID}
                    
                    strongSelf.optographIDs = results.models
                        .filter{ $0.isPublished && !$0.isUploading}
                        .map{$0.ID}
                    
                    //                    strongSelf.collectionView!.performBatchUpdates({
                    //                        strongSelf.collectionView!.deleteItemsAtIndexPaths(results.delete.map { NSIndexPath(forItem: $0 + 1, inSection: 0) })
                    //                        strongSelf.collectionView!.reloadItemsAtIndexPaths(results.update.map { NSIndexPath(forItem: $0 + 1, inSection: 0) })
                    //                        strongSelf.collectionView!.insertItemsAtIndexPaths(results.insert.map { NSIndexPath(forItem: $0 + 1, inSection: 0) })
                    //                        }, completion: nil)
                }
                })
            .startWithNext { _ in
                self.collectionView?.reloadData()
        }
        
        tabController?.pageStatus.producer.startWithNext { val in
            if val == .Profile {
                self.collectionViewModel.refreshNotification.notify(())
                self.collectionViewModel.isActive.value = true
            } else {
                self.collectionViewModel.isActive.value = false
            }
        }
    }
    func readAllNotification() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("activities/read_all")
    }
    
    deinit {
        logRetain()
    }
    func goToFeeds() {
        if isProfileVisit {
            navigationController?.popViewControllerAnimated(true)
        } else {
            tabController!.leftButtonAction()
        }
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY:CGFloat  = scrollView.contentOffset.y
        
        if (offsetY > 230) {
            UIView.animateWithDuration(0.5, animations: {
                self.headerView.hidden = false
                self.navigationController?.navigationBarHidden = true
                }, completion:nil)
        } else if  (offsetY < 230){
            UIView.animateWithDuration(0.5, animations: {
                self.headerView.hidden = true
                self.navigationController?.navigationBarHidden = false
                }, completion:nil)
        }
    }
    
    
    func reloadView() {
        collectionViewModel.refreshNotification.dispose()
        
        profileViewModel = ProfileViewModel(personID: SessionService.personID)
        collectionViewModel = ProfileOptographsViewModel(personID: SessionService.personID)
        
        rightBarButton.rac_text <~ profileViewModel.isEditing.producer.mapToTuple("Save", String.iconWithName(.More))
        
        profileViewModel.isEditing.producer.startWithNext { [weak self] isEditing in
            if isEditing {
                self?.navigationItem.leftBarButtonItem = self!.barButtonItem
            }
            self?.navigationItem.leftBarButtonItem = isEditing ? self!.barButtonItem : self?.originalBackButton
            
        }
        
        profileViewModel.isEditing.producer.skip(1).startWithNext { [weak self] isEditing in
            if let strongSelf = self {
                
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                strongSelf.collectionView!.performBatchUpdates(nil, completion: { _ in CATransaction.commit() })
                
                if isEditing {
                    self?.rightBarButton.frame = CGRect(x: 0, y: -2, width: 40, height: 21)
                    let collectionViewSize = strongSelf.collectionView!.frame.size
                    //let textHeight = calcTextHeight(strongSelf.profileViewModel.text.value, withWidth: collectionViewSize.width - 28, andFont: UIFont.fontDisplay(12, withType: .Regular))
                    
                    let cellSize = strongSelf.collectionView(strongSelf.collectionView!, layout: strongSelf.collectionView!.collectionViewLayout, sizeForItemAtIndexPath: NSIndexPath(forItem: 0, inSection: 0))
                    
                    //let headerHeight = strongSelf.view.frame.height * 0.5 + textHeight
                    
                    let headerHeight = cellSize.height + 20
                    
                    strongSelf.editOverlayView.frame = CGRect(x: 0, y: headerHeight, width: collectionViewSize.width, height: collectionViewSize.height - headerHeight)
                    
                    strongSelf.collectionView!.contentOffset = CGPoint(x: 0,y:-44)
                    strongSelf.title = "Edit My Profile"
                } else {
                    self?.rightBarButton.frame = CGRect(x: 0, y: -2, width: 20, height: 21)
                    strongSelf.title = "My Profile"
                    
                }
                
                strongSelf.collectionView!.scrollEnabled = !isEditing
            }
        }
        
        collectionViewModel.results.producer
            .filter {$0.changed}
            .delayAllUntil(collectionViewModel.isActive.producer)
            .observeOnMain()
            .on(next: { [weak self] results in
                if let strongSelf = self {
                    strongSelf.optographIDsNotUploaded = results.models
                        .filter{ !$0.isPublished && !$0.isUploading}
                        .map{$0.ID}
                    
                    strongSelf.optographIDs = results.models
                        .filter{ $0.isPublished && !$0.isUploading}
                        .map{$0.ID}
                }
                })
            .startWithNext { _ in
                self.collectionView?.reloadData()
        }
        
        profileViewModel.followTabTouched.producer.startWithNext { [weak self] isFollowTabTap in
            if isFollowTabTap {
                self!.isFollowClicked = true
                self!.isNotifClicked = false
            } else {
                self!.isFollowClicked = false
                self!.isNotifClicked = false
            }
            self!.collectionView?.reloadData()
            self!.collectionViewModel.refreshNotification.notify(())
        }
        
        profileViewModel.notifTabTouched.producer.startWithNext { [weak self] isNotifTabTap in
            if isNotifTabTap {
                print("click notification")
                self!.isNotifClicked = true
                self!.isFollowClicked = false
                self!.readAllNotification()
                    .on(
                        completed: { [weak self] in
                        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                        ActivitiesService.unreadCount.value = 0
                    }).start()
                
                self!.collectionView?.reloadData()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if (Defaults[.SessionNeedRefresh]) {
            print("needs to refresh")
            self.reloadView()
            Defaults[.SessionNeedRefresh] = false
        }
        
        tabController?.delegate = self
        
        CoreMotionRotationSource.Instance.start()
        
        profileViewModel.refreshData()
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.fontDisplay(20, withType: .Semibold),
            NSForegroundColorAttributeName: UIColor.blackColor(),
        ]
        
        if isProfileVisit {
            tabController!.disableScrollView()
            collectionViewModel.isActive.value = true
        }
        self.navigationController?.navigationBar.tintColor = UIColor(hex:0xFF5E00)
        
        if fromLoginPage {
            goToFeeds()
            fromLoginPage = false
        }
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if isProfileVisit {
            tabController!.enableScrollView()
        }
        CoreMotionRotationSource.Instance.stop()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        collectionViewModel.isActive.value = false
        self.navigationController?.navigationBarHidden = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (isFollowClicked || isNotifClicked) && profileViewModel.isMe {
            return 2
        } else {
            print("count3",optographIDs.count)
            print(("count2",optographIDsNotUploaded.count > 0 ? 1:0))
            print("count1",optographIDsNotUploaded.count)
            print("number of items",optographIDs.count + 1 + (optographIDsNotUploaded.count > 0 ? 1:0))
            return optographIDs.count + 1 + (optographIDsNotUploaded.count > 0 ? 1:0)
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("top-cell", forIndexPath: indexPath) as! ProfileHeaderCollectionViewCell
            print("ProfileHeaderCollectionViewCell")
            
            cell.bindViewModel(profileViewModel)
            cell.navigationController = navigationController as? NavigationController
            cell.parentViewController = self
            
            return cell
        } else if (indexPath.item == 1 && !isFollowClicked && optographIDsNotUploaded.count != 0 && !isNotifClicked ) && profileViewModel.isMe{
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("upload-cell", forIndexPath: indexPath) as! ProfileUploadCollectionViewCell
            print("ProfileUploadCollectionViewCell")
            
            cell.optographIDsNotUploaded = optographIDsNotUploaded
            cell.navigationController = navigationController as? NavigationController
            cell.refreshNotification = collectionViewModel.refreshNotification
            cell.reloadTable()
            
            return cell
            
        } else if (indexPath.item == 1 && isFollowClicked && !isNotifClicked) && profileViewModel.isMe{
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("followers-cell", forIndexPath: indexPath) as! ProfileFollowersViewCell
            print("ProfileFollowersViewCell")
            cell.navigationController = navigationController as? NavigationController
            cell.viewIsActive()
            
            
            return cell
            
        } else if (indexPath.item == 1 && isNotifClicked) && profileViewModel.isMe {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("notification-cell", forIndexPath: indexPath) as! NotificationTableViewCell
            print("NotificationTableViewCell")
            cell.navigationController = navigationController as? NavigationController
            
            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("tile-cell", forIndexPath: indexPath) as! ProfileTileCollectionViewCell
            var cellCount:Int = 1
            print("ProfileTileCollectionViewCell")
            if optographIDsNotUploaded.count != 0 {
                cellCount += 1
            }
            if optographIDs.count != 0 {
                if let optographID:UUID = optographIDs[indexPath.item - cellCount] {
                    cell.bind(optographID)
                    cell.refreshNotification = collectionViewModel.refreshNotification
                    cell.navigationController = navigationController as? NavigationController
                    cell.backgroundColor = UIColor.blackColor()
                }
            }
            
            return cell
        }
    }
    
    func addLabel() {
        
        if (optographIDs.count == 0) {
            let label = UILabel()
            label.anchorToEdge(.Bottom, padding: view.frame.height*0.25, width: 200, height: 30)
            label.text = "Nothing to show"
            label.font = UIFont.fontDisplay(25, withType: .Regular)
            label.textAlignment = .Center
            view.addSubview(label)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.item == 0 {
            let textHeight = calcTextHeight(profileViewModel.text.value, withWidth: collectionView.frame.width - 28, andFont: UIFont.displayOfSize(12, withType: .Regular))
            return CGSize(width: self.view.frame.width, height: 267 + textHeight)
        } else if indexPath.item == 1 && (isFollowClicked || isNotifClicked) && profileViewModel.isMe{
            let textHeight = calcTextHeight(profileViewModel.text.value, withWidth: collectionView.frame.width - 28, andFont: UIFont.displayOfSize(12, withType: .Regular))
            return CGSize(width: self.view.frame.width, height: self.view.frame.height - (267 + textHeight))
        } else if (indexPath.item == 1 && !isFollowClicked && optographIDsNotUploaded.count != 0) && profileViewModel.isMe{
            let width = (self.view.frame.size.width)
            return CGSize(width: width, height: CGFloat(optographIDsNotUploaded.count * 75) + CGFloat(optographIDsNotUploaded.count * 1))
        } else {
            let width = ((self.view.frame.size.width)/3) - 2
            return CGSize(width: width, height: width)
        }
    }
    
    //    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
    //        return UIEdgeInsetsMake(0, 100, self.view.frame.width, 0)
    //    }
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.item == 0 {
            
        }
        
        if indexPath.item % 3 == 1 && indexPath.item > optographIDs.count - 7 {
            collectionViewModel.loadMoreNotification.notify(())
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        //        (cell as! CollectionViewCell).didEndDisplay()
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.item != 0 && !isFollowClicked && !(indexPath.item == 1 && optographIDsNotUploaded.count != 0){
            var cellCount:Int = 1
            
            if optographIDsNotUploaded.count != 0 {
                cellCount += 1
            }
            let detailsViewController = DetailsTableViewController(optoList: [optographIDs[indexPath.item - cellCount]])
            detailsViewController.cellIndexpath = cellCount
            navigationController?.pushViewController(detailsViewController, animated: true)
        }
    }
    
    dynamic private func tapLeftBarButton() {
        profileViewModel.cancelEdit()
    }
    
    func report() -> SignalProducer<EmptyResponse, ApiError> {
        return ApiService<EmptyResponse>.post("optographs/\(profileViewModel.personID)/report")
    }
    
    dynamic private func tapRightBarButton() {
        
        if profileViewModel.isEditing.value {
            profileViewModel.saveEdit()
        } else {
            let settingsSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            if profileViewModel.isMe {
                settingsSheet.addAction(UIAlertAction(title: "Sign out", style: .Destructive, handler: { _ in
                    
                    if self.optographIDsNotUploaded.count != 0 {
                        let confirmAlert = UIAlertController(title: "Are you sure want to logout?", message: "Some optographs are still not uploaded and will be deleted if you logout.", preferredStyle: .Alert)
                        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
                        confirmAlert.addAction(UIAlertAction(title: "Logout", style: .Default, handler: { _ in
                            SessionService.logoutReset()
                            SessionService.logout()
                        }))
                        
                        self.navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
                    } else {
                        SessionService.logoutReset()
                        SessionService.logout()
                    }
                }))
            } else {
                settingsSheet.addAction(UIAlertAction(title: "Report user", style: .Destructive, handler: { _ in
                    let confirmAlert = UIAlertController(title: "Are you sure?", message: "This action will message one of the moderators.", preferredStyle: .Alert)
                    confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
                    confirmAlert.addAction(UIAlertAction(title: "Report", style: .Destructive, handler: { _ in
                        self.report().start()
                    }))
                    self.navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
                }))
            }
            
            settingsSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
            
            navigationController?.presentViewController(settingsSheet, animated: true, completion: nil)
        }
    }
}
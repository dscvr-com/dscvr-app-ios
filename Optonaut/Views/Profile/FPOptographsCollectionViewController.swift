//
//  FPOptographsCollectionViewController.swift
//  DSCVR
//
//  Created by Thadz on 22/07/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SpriteKit
import SwiftyUserDefaults

class OptographIds {
    class var sharedInstance: OptographIds {
        struct Static {
            static var instance: OptographIds?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = OptographIds()
        }
        
        return Static.instance!
    }
    var optographIDs: [UUID] = [];
}

protocol FPOptographsCollectionViewControllerDelegate {
    func optographSelected(optographID: String);
}

class FPOptographsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private var profileViewModel: ProfileViewModel;
//    private var collectionViewModel: ProfileOptographsViewModel;
//    private var feedsModel = FeedOptographCollectionViewModel();
    private var optographIDs: [UUID] = [];
    private var feedIDs: [UUID] = [];
    
    var startStory = false;
    var delegate: FPOptographsCollectionViewControllerDelegate?
    
    let OptographIdsData = OptographIds.sharedInstance
    
    init(personID: UUID) {
        
        profileViewModel = ProfileViewModel(personID: personID);
//        collectionViewModel = ProfileOptographsViewModel(personID: personID);
        optographIDs = OptographIdsData.optographIDs
        
        super.init(collectionViewLayout: UICollectionViewLeftAlignedLayout());
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }

    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.title = "Create a Story";
        
        collectionView!.backgroundColor = UIColor(hex:0xf7f7f7);
        collectionView!.alwaysBounceVertical = true;
        collectionView!.delegate = self;
        collectionView!.dataSource = self;
        
        collectionView!.registerClass(ProfileTileCollectionViewCell.self, forCellWithReuseIdentifier: "tile-cell");
        
        //collectionViewModel = ProfileOptographsViewModel(personID: SessionService.personID);
        
//        collectionViewModel.results.producer
//            .filter{$0.changed}
//            .delayAllUntil(collectionViewModel.isActive.producer)
//            .observeOnMain()
//            .on(next: { [weak self] results in
//                
//                if let strongSelf = self {
//                    
//                    strongSelf.optographIDs = results.models
//                        .filter{ $0.isPublished || $0.isUploading}
//                        .map{$0.ID}
//                    
//                    print("over here");
//                    print("id count: \(strongSelf.optographIDs.count)");
//                    strongSelf.feedsModel.isActive.value = true;
//                    strongSelf.feedsModel.refresh()
//                    strongSelf.collectionView?.reloadData();
//                    strongSelf.collectionViewModel.isActive.value = false;
//                }
//                })
//            .start();
//        
//        feedsModel.results.producer
//            .filter {return $0.changed }
//            .delayAllUntil(feedsModel.isActive.producer)
//            .observeOnMain()
//            .on(next: { [weak self] results in
//                print("reload data =======")
//                
//                if let strongSelf = self {
//                    let visibleOptographID: UUID? = strongSelf.optographIDs.isEmpty ? nil : strongSelf.optographIDs[strongSelf.collectionView!.indexPathsForVisibleItems().first!.row]
//                    strongSelf.feedIDs = results.models.map { $0.ID }
//                    strongSelf.optographIDs = strongSelf.optographIDs + results.models.map { $0.ID }
//                    print("feedIDs: \(strongSelf.optographIDs.count)");
//                    
//                    strongSelf.collectionView!.reloadData()
//                    
//                }
//                })
//            .start()
        
        let dismissButton = UIButton(frame: CGRect(x: 0, y: 0.0, width: 40.0, height: 40.0))
        //        dismissButton.backgroundColor = UIColor.whiteColor()
        dismissButton.addTarget(self, action: #selector(dismissStorytelling), forControlEvents: .TouchUpInside)
        dismissButton.setImage(UIImage(named: "close_icn"), forState: UIControlState.Normal)
        
        let rightBarButton = UIBarButtonItem(customView: dismissButton)
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func dismissStorytelling(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        print("did appear");
        
//        collectionViewModel.isActive.value = true;
//        collectionViewModel.refresh();
    }
    //UICollectionView Data Source
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1;
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return optographIDs.count;
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("tile-cell", forIndexPath: indexPath) as! ProfileTileCollectionViewCell;
        
        let optographID = optographIDs[indexPath.item];
        cell.bind(optographID);
        //cell.refreshNotification = collectionViewModel.refreshNotification;
        cell.navigationController = navigationController as? NavigationController;
        cell.backgroundColor = UIColor.blackColor();
        
        return cell
    }
    
    //UICollectionView Delegate
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if startStory{
            let detailsViewController = StoryDetailsTableViewController(optographId: optographIDs[indexPath.item])
            detailsViewController.cellIndexpath = indexPath.item
            detailsViewController.isStorytelling = true
            
            print("id: \(optographIDs[indexPath.item])");
            
            navigationController?.pushViewController(detailsViewController, animated: true)
        }
        else{
            delegate?.optographSelected(optographIDs[indexPath.item]);
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
    
    //UICollectionViewFlowLayout Delegate
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = ((self.view.frame.size.width)/3) - 2;
        return CGSize(width: width, height: width);
    }

}

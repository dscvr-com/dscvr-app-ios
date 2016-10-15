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
import SQLite

protocol FPOptographsCollectionViewControllerDelegate {
    func optographSelected(optographID: String);
}

class FPOptographsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private var profileViewModel: ProfileViewModel;
    private var pfModel:FPModel
    private var optographIDs: [UUID] = [];
    
    var startStory = false;
    var delegate: FPOptographsCollectionViewControllerDelegate?
    
    init(personID: UUID) {
        
        profileViewModel = ProfileViewModel(personID: personID);
        pfModel = FPModel(personID: personID)
        
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
        
        
        pfModel.results.producer
            .delayAllUntil(pfModel.isActive.producer)
            .observeOnMain()
            .on(next: { [weak self] results in
                
                if let strongSelf = self {
                    print(results)
                    strongSelf.optographIDs = results
                        .map{$0.ID}
                }
            })
            .start { _ in
                self.collectionView?.reloadData()
        }
        
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
        
        pfModel.isActive.value = true;
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        pfModel.isActive.value = false
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

class FPModel {
    let refreshNotification = NotificationSignal<Void>()
    let results = MutableProperty<[Optograph]>([])
    let isActive = MutableProperty<Bool>(false)
    private var refreshTimer: NSTimer?
    
    init(personID: UUID) {
        
        let query = OptographTable
            .select(*)
            .join(PersonTable, on: OptographTable[OptographSchema.personID] == PersonTable[PersonSchema.ID])
            .join(.LeftOuter, LocationTable, on: LocationTable[LocationSchema.ID] == OptographTable[OptographSchema.locationID])
            .join(.LeftOuter, StoryTable, on: StoryTable[StorySchema.ID] == OptographTable[OptographSchema.storyID])
            .filter(PersonTable[PersonSchema.ID] == personID && OptographTable[OptographSchema.storyID] == "")
        
        refreshNotification.signal
            .takeWhile { _ in SessionService.isLoggedIn }
            .flatMap(.Latest) { _ in
                DatabaseService.query(.Many, query: query)
                    .observeOnUserInteractive()
                    .on(next: { row in
                        Models.optographs.touch(Optograph.fromSQL(row))
                        Models.persons.touch(Person.fromSQL(row))
                        Models.locations.touch(row[OptographSchema.locationID] != nil ? Location.fromSQL(row) : nil)
                    })
                    .map(Optograph.fromSQL)
                    .ignoreError()
                    .collect()
                    .startOnUserInteractive()
            }
            .observeOnMain()
            .observeNext {self.results.value = $0 }
        
        isActive.producer.skipRepeats().startWithNext { [weak self] isActive in
            if isActive {
                self?.refresh()
            }
        }
    }
    
    func refresh() {
        refreshNotification.notify(())
    }
}

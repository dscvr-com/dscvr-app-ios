//
//  StorytellingCollectionViewController.swift
//  DSCVR
//
//  Created by Thadz on 09/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class StorytellingCollectionViewController: UICollectionViewController,TabControllerDelegate {
    
    private var profileViewModel: ProfileViewModel;
    private var collectionViewModel: ProfileOptographsViewModel;
    private var feedsModel = FeedOptographCollectionViewModel();
    private var optographIDs: [UUID] = [];
    private var feedIDs: [UUID] = [];
    
    private var storyIDs: [UUID] = []; //user stories
    private var storyFeed: [UUID] = []; //feed available stories
    
    var startStory = false;
    var startOpto = ""
    var delegate: FPOptographsCollectionViewControllerDelegate?
    
    
    
    init(personID: UUID) {
        
        profileViewModel = ProfileViewModel(personID: personID);
        collectionViewModel = ProfileOptographsViewModel(personID: personID);
        
//        let width = ((view.frame.size.width)/3) - 20;
        
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
//        layout.itemSize = CGSize(width: width, height: width)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
//        layout.footerReferenceSize = CGSizeMake(100, 50)
        
        super.init(collectionViewLayout: layout);
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.title = "Stories";
        
        tabController?.delegate = self
        
        collectionView!.backgroundColor = UIColor(hex:0xf7f7f7);
        collectionView!.alwaysBounceVertical = true;
        collectionView!.delegate = self;
        collectionView!.dataSource = self;
        collectionView?.backgroundColor = UIColor.whiteColor()
        
        collectionView!.registerClass(StorytellingCollectionViewCell.self, forCellWithReuseIdentifier: "tile-cell");
        collectionView!.registerClass(ProfileTileCollectionViewCell.self, forCellWithReuseIdentifier: "tile-cell-feed");
        collectionView!.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footerView")
        collectionView!.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView")
        
        collectionViewModel = ProfileOptographsViewModel(personID: SessionService.personID);
        
        collectionViewModel.results.producer
            .filter{$0.changed}
            .delayAllUntil(collectionViewModel.isActive.producer)
            .observeOnMain()
            .on(next: { [weak self] results in
                
                if let strongSelf = self {
                    
                    strongSelf.optographIDs = results.models
                        .filter{ $0.isPublished || $0.isUploading}
                        .map{$0.ID}
                    
                    print("over here");
                    print("id count: \(strongSelf.optographIDs.count)");
                    strongSelf.feedsModel.isActive.value = true;
                    strongSelf.feedsModel.refresh()
                    strongSelf.collectionView?.reloadData();
                    strongSelf.collectionViewModel.isActive.value = false;
                }
                })
            .start();
        
        feedsModel.results.producer
            .filter {return $0.changed }
            //.retryUntil(0.1, onScheduler: QueueScheduler(queue: queue)) { [weak self] in self?.collectionView!.decelerating == false && self?.collectionView!.dragging == false }
            .delayAllUntil(feedsModel.isActive.producer)
            .observeOnMain()
            .on(next: { [weak self] results in
                print("reload data =======")
                
                if let strongSelf = self {
                    let visibleOptographID: UUID? = strongSelf.optographIDs.isEmpty ? nil : strongSelf.optographIDs[strongSelf.collectionView!.indexPathsForVisibleItems().first!.row]
                    strongSelf.feedIDs = results.models.map { $0.ID }
                    strongSelf.optographIDs = strongSelf.optographIDs + results.models.map { $0.ID }
                    print("feedIDs: \(strongSelf.optographIDs.count)");
                    
                    strongSelf.collectionView!.reloadData()
                    
                }
                })
            .start()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        print("did appear");
        
        collectionViewModel.isActive.value = true;
        collectionViewModel.refresh();
    }
    
    func showDetailsViewController(){
        //88a257df-2008-4d7b-ae44-7ea603011867
        let detailsViewController = DetailsTableViewController(optographId: startOpto)
        let optoCollection = FPOptographsCollectionViewController(personID: SessionService.personID)
        optoCollection.startStory = true
        
        detailsViewController.cellIndexpath = 1
        detailsViewController.isStorytelling = true
        
        let navCon = UINavigationController()
        navCon.viewControllers = [optoCollection]
        
       // navigationController?.pushViewController(optoCollection, animated: true)
        navigationController?.presentViewController(navCon, animated: true, completion: nil)
    }

    //UICollectionView Data Source
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2;
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return optographIDs.count;
        
        
        return 5;
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var storyCell = UICollectionViewCell()
        
        if  indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("tile-cell", forIndexPath: indexPath) as! StorytellingCollectionViewCell;
            
            storyCell = cell
            
            cell.layer.shadowColor = UIColor.grayColor().CGColor;
            cell.layer.shadowOffset = CGSizeMake(0, 2.0);
            cell.layer.shadowRadius = 2.0;
            cell.layer.shadowOpacity = 1.0;
            cell.layer.masksToBounds = false;
            cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).CGPath;
        }
        else{
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("tile-cell-feed", forIndexPath: indexPath) as! ProfileTileCollectionViewCell;
            storyCell = cell
            
            cell.layer.shadowColor = UIColor.grayColor().CGColor;
            cell.layer.shadowOffset = CGSizeMake(0, 2.0);
            cell.layer.shadowRadius = 2.0;
            cell.layer.shadowOpacity = 1.0;
            cell.layer.masksToBounds = false;
            cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).CGPath;
        }
        
        
        
//        let optographID = optographIDs[indexPath.item];
//        cell.bind(optographID);
//        cell.refreshNotification = collectionViewModel.refreshNotification;
//        cell.navigationController = navigationController as? NavigationController;
        
        storyCell.contentView.layer.cornerRadius = 10.0;
        storyCell.contentView.layer.borderWidth = 1.0;
        storyCell.contentView.layer.borderColor = UIColor.clearColor().CGColor
        storyCell.contentView.layer.masksToBounds = true;
//
//        cell.backgroundColor = UIColor.blackColor();
        
        return storyCell
    }
    
    //UICollectionView Delegate
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    //UICollectionViewFlowLayout Delegate
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var reusableView = UICollectionReusableView()
        
        
        if kind == UICollectionElementKindSectionFooter{
            let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: "footerView", forIndexPath: indexPath)
            
//            let footerLabel = UILabel()
//            footerLabel.text = "footer label"
//            footerLabel.frame = CGRectMake(0, 0, 0, 0);
//            footerLabel.sizeToFit()
//            footerLabel.center = CGPointMake(self.view.center.x, 50/2)
//            footerView.addSubview(footerLabel)
            
            let startStoryButton = UIButton()
            startStoryButton.setTitle("Create a Story", forState: UIControlState.Normal)
            startStoryButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 22.0)
            startStoryButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
//            startStoryButton.sizeToFit()
            startStoryButton.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width - 40, height: 50.0)
            startStoryButton.center = CGPointMake(self.view.center.x, 200/2)
            startStoryButton.addTarget(self, action: #selector(showDetailsViewController), forControlEvents: UIControlEvents.TouchUpInside)
            startStoryButton.backgroundColor = UIColor.orangeColor()
            startStoryButton.layer.cornerRadius = 10.0
            footerView.addSubview(startStoryButton)
            
            let lineView = UIView(frame: CGRect(x: 0, y: 20, width: self.view.frame.width, height: 1))
            lineView.backgroundColor = UIColor.lightGrayColor()
            
            footerView.addSubview(lineView)
            
            reusableView = footerView
        }
        else if kind == UICollectionElementKindSectionHeader{
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", forIndexPath: indexPath)
            
            let lineView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 1))
            lineView.backgroundColor = UIColor.lightGrayColor()
            lineView.center = CGPointMake(self.view.center.x, 25/2)
            
            let storiesLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            storiesLabel.text = "YOUR STORIES"
            storiesLabel.font = UIFont(name: "Avenir-Heavy", size: 13.0)
            storiesLabel.textAlignment = NSTextAlignment.Center
            storiesLabel.sizeToFit()
            storiesLabel.frame = CGRect(x: 0, y: 0, width: storiesLabel.frame.size.width + 20, height: storiesLabel.frame.size.height)
            storiesLabel.backgroundColor = UIColor.whiteColor()
            storiesLabel.textColor = UIColor.blackColor()
            storiesLabel.center = lineView.center
            
            headerView.addSubview(lineView)
            headerView.addSubview(storiesLabel)
            
//            headerView.backgroundColor = UIColor.blueColor()
            
            reusableView = headerView
        }
        
        return reusableView;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize{
        
        var referenceSize = CGSize()
        
        if section == 0{
            referenceSize = CGSizeMake(self.view.width, 0)
        }
        else{
            referenceSize = CGSizeMake(self.view.width, 200)
        }
        
        return referenceSize
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
    
        var referenceSize = CGSize()
        
        if section == 0{
            referenceSize = CGSizeMake(self.view.width, 0)
        }
        else{
            referenceSize = CGSizeMake(self.view.width, 25.0)
        }
        
        return referenceSize
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var varyingSize = CGSize()
        
        if indexPath.section == 0 {
            let width = ((self.view.frame.size.width)/3) - 20;
            varyingSize = CGSize(width: width, height: width + 40);
        }
        
        else{
            let width = ((self.view.frame.size.width)/3) - 20;
            varyingSize = CGSize(width: width, height: width);
        }
        
        return varyingSize;
    }
}

//
//  StorytellingCollectionViewController.swift
//  DSCVR
//
//  Created by Thadz on 09/08/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class StorytellingCollectionViewController: UICollectionViewController {
    
    private var profileViewModel: ProfileViewModel;
    private var collectionViewModel: ProfileOptographsViewModel;
    private var feedsModel = FeedOptographCollectionViewModel();
    private var optographIDs: [UUID] = [];
    private var feedIDs: [UUID] = [];
    
    private var storyIDs: [UUID] = []; //user stories
    private var storyFeed: [UUID] = []; //feed available stories
    
    var startStory = false;
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
        
        self.title = "Optographs";
        
        collectionView!.backgroundColor = UIColor(hex:0xf7f7f7);
        collectionView!.alwaysBounceVertical = true;
        collectionView!.delegate = self;
        collectionView!.dataSource = self;
        
        collectionView!.registerClass(StorytellingCollectionViewCell.self, forCellWithReuseIdentifier: "tile-cell");
        collectionView!.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footerView")
        
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
        let detailsViewController = DetailsTableViewController(optographId: "88a257df-2008-4d7b-ae44-7ea603011867")
        detailsViewController.cellIndexpath = 1
        detailsViewController.isStorytelling = true
        navigationController?.pushViewController(detailsViewController, animated: true)
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
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("tile-cell", forIndexPath: indexPath) as! StorytellingCollectionViewCell;
        
//        let optographID = optographIDs[indexPath.item];
//        cell.bind(optographID);
//        cell.refreshNotification = collectionViewModel.refreshNotification;
//        cell.navigationController = navigationController as? NavigationController;
        
        cell.contentView.layer.cornerRadius = 10.0;
        cell.contentView.layer.borderWidth = 1.0;
        cell.contentView.layer.borderColor = UIColor.clearColor().CGColor
        cell.contentView.layer.masksToBounds = true;
//
//        cell.backgroundColor = UIColor.blackColor();
        
        return cell
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
            startStoryButton.setTitle("Start Story", forState: UIControlState.Normal)
            startStoryButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 22.0)
            startStoryButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            startStoryButton.sizeToFit()
            startStoryButton.center = CGPointMake(self.view.center.x, 50/2)
            startStoryButton.addTarget(self, action: #selector(showDetailsViewController), forControlEvents: UIControlEvents.TouchUpInside)
            footerView.addSubview(startStoryButton)
            
            reusableView = footerView
        }
        
        return reusableView;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize{
        
        var referenceSize = CGSize()
        
        if section == 0{
            referenceSize = CGSizeMake(self.view.width, 0)
        }
        else{
            referenceSize = CGSizeMake(self.view.width, 50)
        }
        
        return referenceSize
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 5;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 5;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = ((self.view.frame.size.width)/3) - 20;
        return CGSize(width: width, height: width + 40);
    }
}

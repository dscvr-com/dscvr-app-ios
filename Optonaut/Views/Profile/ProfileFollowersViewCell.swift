//
//  ProfileFollowersViewCell.swift
//  Iam360
//
//  Created by robert john alkuino on 6/22/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import Kingfisher

class ProfileFollowersViewCell: UICollectionViewCell,UITableViewDataSource, UITableViewDelegate{
    
    
    var tableView: UITableView!
//    var optographIDsNotUploaded: [UUID]?
    var data = ["San Francisco","New York","San Jose","Chicago","Los Angeles","Austin","Seattle", "Sacramento"]
    
    weak var navigationController: NavigationController?
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: Int(frame.size.width), height:Int(frame.size.height)));
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.registerClass(FollowersTableViewCell.self, forCellReuseIdentifier: "userFollowers");
        contentView.addSubview(tableView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userFollowers") as! FollowersTableViewCell
        
        //cell.bind(optographIDsNotUploaded![indexPath.item])
        
        return cell;
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        let detailsViewController = DetailsTableViewController(optographId: optographIDsNotUploaded![indexPath.item])
//        detailsViewController.cellIndexpath = indexPath.item
//        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    func reloadTable() {
        tableView.reloadData()
    }
    
}

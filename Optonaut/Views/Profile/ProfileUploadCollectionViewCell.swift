//
//  ProfileUploadCollectionViewCell.swift
//  Iam360
//
//  Created by robert john alkuino on 6/17/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//
import Foundation
import SpriteKit
import ReactiveCocoa
import SceneKit
import Kingfisher

class ProfileUploadCollectionViewCell: UICollectionViewCell,UITableViewDataSource, UITableViewDelegate{
    
    var tableView =  UITableView()
    var optographIDsNotUploaded: [UUID]?
    var refreshNotification = NotificationSignal<Void>()
    
    weak var navigationController: NavigationController?
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
//        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: Int(frame.size.width), height:Int(frame.size.height)));
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(UploadItemCell.self, forCellReuseIdentifier: "uploadImages")
        contentView.addSubview(tableView)
        tableView.fillSuperview()

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optographIDsNotUploaded!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("uploadImages") as! UploadItemCell
        
        cell.bind(optographIDsNotUploaded![indexPath.item])
        cell.selectionStyle = .None
        cell.uploadFinish.producer.startWithNext{ val in
            if val {
                print("upload finish")
                self.refreshNotification.notify()
            }
        }
        
        return cell;
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let detailsViewController = DetailsTableViewController(optoList:[optographIDsNotUploaded![indexPath.item]])
        detailsViewController.cellIndexpath = indexPath.item
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    func reloadTable() {
        tableView.fillSuperview()
        tableView.reloadData()
    
    }

}

//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import PureLayout_iOS
import RealmSwift
import Alamofire
import SwiftyJSON
import Refresher

class OptographTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var didSetupContraints = false
    var items = Realm().objects(Optograph).sorted("createdAt", ascending: false)
    let tableView = UITableView()
    let navBarView = UINavigationBar()
    var navController: UINavigationController?
    var source = ""
    
    required init(source: String, navController: UINavigationController?) {
        super.init(nibName: nil, bundle: nil)
        self.source = source
        self.navController = navController
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        
        tableView.registerClass(OptographTableViewCell.self, forCellReuseIdentifier: "cell")
        
        tableView.addPullToRefreshWithAction {
            NSOperationQueue().addOperationWithBlock {
                self.fetchData()
            }
        }
        
        fetchData()
        
        view.addSubview(tableView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchData()
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        
        super.updateViewConstraints()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let textString = (items[indexPath.row].text + items[indexPath.row].user!.userName) as NSString
        let textBounds = textString.sizeWithAttributes([NSFontAttributeName: UIFont.systemFontOfSize(17)])
        let numberOfLines = ceil(textBounds.width / (view.frame.width - 30))
        return view.frame.width + 70 + numberOfLines * 28
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! OptographTableViewCell
        cell.data = items[indexPath.row]
        cell.applyData()
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchData() {
        Api().get(source, authorized: true,
            success: { jsonArray in
                let realm = Realm()
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"
                
                realm.write {
                    for (index, optographJson): (String, JSON) in jsonArray! {
                        let user = User()
                        user.id = optographJson["user"]["id"].intValue
                        user.email = optographJson["user"]["email"].stringValue
                        user.userName = optographJson["user"]["user_name"].stringValue
                        realm.add(user, update: true)
                        
                        let optograph = Optograph()
                        optograph.id = optographJson["id"].intValue
                        optograph.text = optographJson["text"].stringValue
                        optograph.numberOfLikes = optographJson["number_of_likes"].intValue
                        optograph.likedByUser = optographJson["liked_by_user"].boolValue
                        optograph.createdAt = dateFormatter.dateFromString(optographJson["created_at"].stringValue)!
                        optograph.user = user
                        realm.add(optograph, update: true)
                    }
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self.tableView.reloadData()
                        self.tableView.stopPullToRefresh()
                    }
                }
            },
            fail: { error in
                println(error)
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.tableView.stopPullToRefresh()
                }
            }
        )
    }
    
}



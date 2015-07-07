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

class OptographTableViewController: UIViewController {

    var items = [Optograph]()
    let tableView = UITableView()
    var navController: UINavigationController?
    let statusBarBackgroundView = UIView()
    
    var viewModel: OptographsViewModel
    
    required init(source: String, navController: UINavigationController?) {
        viewModel = OptographsViewModel(source: source)
        super.init(nibName: nil, bundle: nil)
        self.navController = navController
    }
    
    required init(coder aDecoder: NSCoder) {
        viewModel = OptographsViewModel(source: "")
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusBarBackgroundView.backgroundColor = baseColor()
        navController?.view.addSubview(statusBarBackgroundView)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: nil, action: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        
        tableView.registerClass(OptographTableViewCell.self, forCellReuseIdentifier: "cell")
        
        let refreshAction = {
            NSOperationQueue().addOperationWithBlock {
                self.viewModel.resultsLoading.put(true)
            }
        }
        
        tableView.addPullToRefreshWithAction(refreshAction, withAnimator: RefreshAnimator())
        
        viewModel.results.producer.start(
            next: { results in
                self.items = results
                self.tableView.reloadData()
                self.tableView.stopPullToRefresh()
            },
            error: { _ in
                self.tableView.stopPullToRefresh()
        })
        
        viewModel.resultsLoading.put(true)
        
        view.addSubview(tableView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        statusBarBackgroundView.hidden = false
        navController?.hidesBarsOnSwipe = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        statusBarBackgroundView.hidden = true
        navController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        navController?.hidesBarsOnSwipe = false
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        statusBarBackgroundView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        statusBarBackgroundView.autoSetDimension(.Height, toSize: 22)
        
        super.updateViewConstraints()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// MARK: - UITableViewDelegate
extension OptographTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let attributes = [NSFontAttributeName: UIFont.robotoOfSize(13, withType: .Light)]
        let textAS = NSAttributedString(string: items[indexPath.row].text, attributes: attributes)
        let tmpSize = CGSize(width: view.frame.width - 38, height: 100000)
        let textRect = textAS.boundingRectWithSize(tmpSize, options: .UsesFontLeading | .UsesLineFragmentOrigin, context: nil)
        let imageHeight = view.frame.width * 0.45
        let restHeight = CGFloat(100) // includes avatar, name, bottom line and spacing
        return imageHeight + restHeight + textRect.height
    }
    
}

// MARK: - UITableViewDataSource
extension OptographTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! OptographTableViewCell
        cell.navController = navController
        cell.bindViewModel(items[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
}
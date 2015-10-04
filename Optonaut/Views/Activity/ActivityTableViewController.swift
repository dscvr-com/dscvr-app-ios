//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class ActivityTableViewController: UIViewController, RedNavbar {
    
    var items = [Activity]()
    let tableView = UITableView()
    
    let viewModel = ActivitiesViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Activity"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        
        tableView.registerClass(ActivityTableViewCell.self, forCellReuseIdentifier: "cell")
        
        viewModel.results.producer.startWithNext { results in
            self.items = results
            self.tableView.reloadData()
        }
        
        view.addSubview(tableView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
    }
    
}


// MARK: - UITableViewDelegate
extension ActivityTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        viewModel.unreadCount.value = 0
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let visibleCells = tableView.visibleCells as! [ActivityTableViewCell]
        
        for cell in visibleCells where !cell.viewModel.isRead.value {
            cell.viewModel.read()
        }
    }
    
}

// MARK: - UITableViewDataSource
extension ActivityTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as! ActivityTableViewCell
        let activity = items[indexPath.row]
        cell.bindViewModel(activity)
        cell.navigationController = navigationController as? NavigationController
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
}

// MARK: - LoadMore
extension ActivityTableViewController: LoadMore {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        checkRow(indexPath) {
            self.viewModel.loadMoreNotificationSignal.notify()
        }
    }
    
}
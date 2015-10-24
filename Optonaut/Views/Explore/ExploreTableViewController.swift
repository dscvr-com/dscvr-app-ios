//
//  ExploreTableViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import Async
import Mixpanel

class ExploreTableViewController: OptographTableViewController, RedNavbar {
    
    private let viewModel = ExploreViewModel()
    private let refreshControl = UIRefreshControl()
    
    required init() {
        viewModel.refreshNotification.notify(())
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Explore"
        
        let searchButton = UIBarButtonItem()
        searchButton.title = String.iconWithName(.Search)
        searchButton.setTitleTextAttributes([NSFontAttributeName: UIFont.iconOfSize(19)], forState: .Normal)
        searchButton.setTitlePositionAdjustment(UIOffset(horizontal: -5, vertical: 0), forBarMetrics: .Default)
        searchButton.target = self
        searchButton.action = "pushSearch"
        navigationItem.setRightBarButtonItem(searchButton, animated: false)
        
        refreshControl.rac_signalForControlEvents(.ValueChanged).toSignalProducer().startWithNext { _ in
            self.viewModel.refreshNotification.notify(())
            Async.main(after: 10) { self.refreshControl.endRefreshing() }
        }
        tableView.addSubview(refreshControl)
        
        viewModel.results.producer
            .on(
                next: { results in
                    self.items = results.models
                    self.tableView.beginUpdates()
                    if !results.delete.isEmpty {
                        self.tableView.deleteRowsAtIndexPaths(results.delete.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .None)
                    }
                    if !results.update.isEmpty {
                        self.tableView.reloadRowsAtIndexPaths(results.update.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .None)
                    }
                    if !results.insert.isEmpty {
                        self.tableView.insertRowsAtIndexPaths(results.insert.map { NSIndexPath(forRow: $0, inSection: 0) }, withRowAnimation: .None)
                    }
                    self.tableView.endUpdates()
                    self.refreshControl.endRefreshing()
                },
                error: { _ in
                    self.refreshControl.endRefreshing()
                }
            )
            .start()
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.refreshNotification.notify(())
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.Explore")
        
        updateNavbarAppear()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.Explore")
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath) as! OptographTableViewCell
        
        cell.deleteCallback = { [weak self] in
            self?.viewModel.refreshNotification.notify(())
        }
        
        return cell
    }
    
    func pushSearch() {
        navigationController?.pushViewController(SearchTableViewController(), animated: false)
    }
    
}


// MARK: - LoadMore
extension ExploreTableViewController: LoadMore {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        checkRow(indexPath) {
            self.viewModel.loadMoreNotification.notify(())
        }
    }
    
}
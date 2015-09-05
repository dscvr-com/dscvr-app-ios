//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit

class ExploreTableViewController: OptographTableViewController, RedNavbar {
    
    private let viewModel = ExploreViewModel()
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Explore"
        
        refreshControl.rac_signalForControlEvents(.ValueChanged).toSignalProducer().start(next: { _ in
            self.viewModel.refreshNotificationSignal.notify()
        })
        tableView.addSubview(refreshControl)
        
        viewModel.results.producer.start(
            next: { results in
                self.items = results
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            },
            error: { _ in
                self.refreshControl.endRefreshing()
            }
        )
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
}


// MARK: - LoadMore
extension ExploreTableViewController: LoadMore {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        checkRow(indexPath) {
            self.viewModel.loadMoreNotificationSignal.notify()
        }
    }
    
}
//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import Async
import ReactiveCocoa

class ActivityTableViewController: UIViewController, RedNavbar {
    
    internal var items = [Activity]()
    internal let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    
    let viewModel = ActivitiesViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Activity"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        
        tableView.registerClass(ActivityStarTableViewCell.self, forCellReuseIdentifier: "star-activity-cell")
        tableView.registerClass(ActivityCommentTableViewCell.self, forCellReuseIdentifier: "comment-activity-cell")
        tableView.registerClass(ActivityViewsTableViewCell.self, forCellReuseIdentifier: "views-activity-cell")
        tableView.registerClass(ActivityFollowTableViewCell.self, forCellReuseIdentifier: "follow-activity-cell")
        
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
        let textWidth = view.frame.width - 80 - 72
        let textHeight = calcTextHeight(items[indexPath.row].text, withWidth: textWidth, andFont: UIFont.displayOfSize(14, withType: .Regular)) + 20
        return max(textHeight, 80)
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let visibleCells = tableView.visibleCells as! [ActivityTableViewCell]
        let unreadActivities = visibleCells.map({ $0.activity }).filter({ !$0.isRead })
        
        SignalProducer<Activity!, NoError>.fromValues(unreadActivities)
            .observeOnUserInteractive()
            .flatMap(.Concat) {
                ApiService<EmptyResponse>.post("activities/\($0.ID)/read")
                    .ignoreError()
                    .startOnUserInteractive()
            }
            .observeOnMain()
            .startWithCompleted { [weak self] in
                self?.viewModel.refreshNotification.notify(())
            }
    }
    
}

// MARK: - UITableViewDataSource
extension ActivityTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let activity = items[indexPath.row]
        let cell: ActivityTableViewCell
        switch activity.type {
        case .Star:
            cell = self.tableView.dequeueReusableCellWithIdentifier("star-activity-cell")! as! ActivityStarTableViewCell
        case .Comment:
            cell = self.tableView.dequeueReusableCellWithIdentifier("comment-activity-cell")! as! ActivityCommentTableViewCell
        case .Views:
            cell = self.tableView.dequeueReusableCellWithIdentifier("views-activity-cell")! as! ActivityViewsTableViewCell
        case .Follow:
            cell = self.tableView.dequeueReusableCellWithIdentifier("follow-activity-cell")! as! ActivityFollowTableViewCell
        default:
            fatalError()
        }
        
        cell.activity = activity
        cell.update()
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
            self.viewModel.loadMoreNotification.notify(())
        }
    }
    
}
//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Async
import Device
import Mixpanel

class FeedTableViewController: OptographTableViewController, NoNavbar {
    
    let viewModel = FeedViewModel()
    let refreshControl = UIRefreshControl()
    
    let recordButtonView = ActionButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordButtonView.setTitle(String.iconWithName(.Logo), forState: .Normal)
        recordButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        recordButtonView.defaultBackgroundColor = .Accent
        recordButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        recordButtonView.layer.cornerRadius = 30
        recordButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushCamera"))
        view.addSubview(recordButtonView)
        
        
        refreshControl.rac_signalForControlEvents(.ValueChanged).toSignalProducer().startWithNext { _ in
            self.viewModel.refreshNotification.notify()
            Async.main(after: 10) { self.refreshControl.endRefreshing() }
        }
        tableView.addSubview(refreshControl)
        
        viewModel.results.producer
            .on(
                next: { items in
                    self.items = items
                    self.tableView.reloadData()
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
        
        updateNavbarAppear()
        
        viewModel.refreshNotification.notify()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.Feed")
        
        tabBarController?.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.delegate = nil
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.Feed")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.contentInset = UIEdgeInsetsZero
        tableView.scrollIndicatorInsets = UIEdgeInsetsZero
    }
    
    override func updateViewConstraints() {
        
        recordButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -20)
        recordButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -20)
        recordButtonView.autoSetDimension(.Width, toSize: 60)
        recordButtonView.autoSetDimension(.Height, toSize: 60)
        
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        viewModel.newResultsAvailable.value = false
    }
    
    func pushCamera() {
        switch UIDevice.currentDevice().deviceType {
        case .IPhone6, .IPhone6Plus, .IPhone6S, .IPhone6SPlus:
            navigationController?.pushViewController(CameraViewController(), animated: false)
        default:
            let alert = UIAlertController(title: "Device not yet supported", message: "Recording isn't available for your device in the current version but will be enabled in a future release.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func pushSearch() {
        navigationController?.pushViewController(SearchTableViewController(), animated: false)
    }
    
}

// MARK: - UITabBarControllerDelegate
extension FeedTableViewController: UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if viewController == navigationController {
            tableView.setContentOffset(CGPointZero, animated: true)
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
}

// MARK: - LoadMore
extension FeedTableViewController: LoadMore {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        checkRow(indexPath) {
            self.viewModel.loadMoreNotification.notify()
        }
    }
    
}
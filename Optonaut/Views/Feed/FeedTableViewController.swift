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

class FeedTableViewController: OptographTableViewController, RedNavbar {
    
    let viewModel = FeedViewModel()
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = String.icomoonWithName(.LogoText)
        
        let cameraButton = UIBarButtonItem()
        cameraButton.image = UIImage.icomoonWithName(.Camera, textColor: .whiteColor(), size: CGSize(width: 24, height: 17))
        cameraButton.target = self
        cameraButton.action = "pushCamera"
        navigationItem.setRightBarButtonItem(cameraButton, animated: false)
        
        let searchButton = UIBarButtonItem()
        searchButton.title = String.icomoonWithName(.MagnifyingGlass)
        searchButton.image = UIImage.icomoonWithName(.MagnifyingGlass, textColor: .whiteColor(), size: CGSize(width: 21, height: 17))
        searchButton.target = self
        searchButton.action = "pushSearch"
        navigationItem.setLeftBarButtonItem(searchButton, animated: false)
        
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
        navigationController?.hidesBarsOnSwipe = true
        
        viewModel.refreshNotification.notify()
        
        navigationController?.navigationBar.setTitleVerticalPositionAdjustment(16, forBarMetrics: .Default)
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.icomoonOfSize(50),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.hidesBarsOnSwipe = false
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        tabBarController?.delegate = nil
    }
    
    override func updateViewConstraints() {
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
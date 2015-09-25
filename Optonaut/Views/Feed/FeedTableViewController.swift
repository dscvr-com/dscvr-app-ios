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

class FeedTableViewController: OptographTableViewController, BlackNavbar {
    
    let viewModel = FeedViewModel()
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = String.icomoonWithName(.LogoText)
        
        let cameraButton = UIBarButtonItem()
        cameraButton.image = UIImage.icomoonWithName(.Camera, textColor: .whiteColor(), size: CGSize(width: 21, height: 17))
        cameraButton.target = self
        cameraButton.action = "pushCamera"
        navigationItem.setRightBarButtonItem(cameraButton, animated: false)
        
        let searchButton = UIBarButtonItem()
        searchButton.title = String.icomoonWithName(.MagnifyingGlass)
        searchButton.image = UIImage.icomoonWithName(.MagnifyingGlass, textColor: .whiteColor(), size: CGSize(width: 21, height: 17))
        searchButton.target = self
        searchButton.action = "pushSearch"
        navigationItem.setLeftBarButtonItem(searchButton, animated: false)
        
        refreshControl.tintColor = .whiteColor()
        refreshControl.rac_signalForControlEvents(.ValueChanged).toSignalProducer().startWithNext { _ in
            self.viewModel.refreshNotification.notify()
            Async.main(after: 10) { self.refreshControl.endRefreshing() }
        }
        
        tableView.backgroundColor = .blackColor()
        tableView.insertSubview(refreshControl, atIndex: 0)
        
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
        
        TabbarOverlayService.hidden = false
        TabbarOverlayService.contentOffsetTop = 0
        
        tabBarController?.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        TabbarOverlayService.scrollOffsetTop = tableView.contentOffset.y + 20
        TabbarOverlayService.scrollOffsetBottom = tableView.contentSize.height - tableView.contentOffset.y - tableView.frame.height
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.delegate = nil
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        TabbarOverlayService.scrollOffsetTop = scrollView.contentOffset.y + 20
        TabbarOverlayService.scrollOffsetBottom = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.height
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        viewModel.newResultsAvailable.value = false
    }
    
    func pushCamera() {
        navigationController?.pushViewController(CameraViewController(), animated: false)
    }
    
    func pushSearch() {
        navigationController?.pushViewController(SearchTableViewController(), animated: false)
    }
    
}

// MARK: - UITabBarControllerDelegate
extension FeedTableViewController: UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if viewController == navigationController {
            tableView.setContentOffset(CGPoint(x: 0, y: -22), animated: true)
//            navigationController?.setNavigationBarHidden(false, animated: true)
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
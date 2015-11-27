//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import Async
import Mixpanel

class ProfileTableViewController: OptographTableViewController, NoNavbar, UniqueView {
    
    private let viewModel: OptographsViewModel
    private let personID: UUID
    
    let refreshControl = UIRefreshControl()
    
    // subviews
    private var headerTableViewCell: ProfileHeaderTableViewCell?
    
    let uniqueIdentifier: String
    
    required init(personID: UUID) {
        self.personID = personID
        viewModel = OptographsViewModel(personID: personID)
        viewModel.refreshNotification.notify(())
        uniqueIdentifier = "profile-\(personID)"
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
        
        tableView.registerClass(ProfileHeaderTableViewCell.self, forCellReuseIdentifier: "profile-header-cell")
        tableView.registerClass(PlaceholderTableViewCell.self, forCellReuseIdentifier: "placeholder-cell")
        tableView.bounces = false
        
        refreshControl.rac_signalForControlEvents(.ValueChanged).toSignalProducer()
            .startWithNext { [weak self] _ in
                self?.viewModel.refreshNotification.notify(())
                Async.main(after: 10) { self?.refreshControl.endRefreshing() }
            }
        tableView.addSubview(refreshControl)
        
        viewModel.results.producer
            .on(
                next: { [weak self] results in
                    let wasEmptyBefore = self?.items.isEmpty ?? false
                    
                    self?.items = results.models
                    
                    if wasEmptyBefore {
                        self?.tableView.reloadData()
                    } else {
                        self?.tableView.beginUpdates()
                        if !results.delete.isEmpty {
                            self?.tableView.deleteRowsAtIndexPaths(results.delete.map { NSIndexPath(forRow: $0 + 1, inSection: 0) }, withRowAnimation: .None)
                        }
                        if !results.update.isEmpty {
                            self?.tableView.reloadRowsAtIndexPaths(results.update.map { NSIndexPath(forRow: $0 + 1, inSection: 0) }, withRowAnimation: .None)
                        }
                        if !results.insert.isEmpty {
                            self?.tableView.insertRowsAtIndexPaths(results.insert.map { NSIndexPath(forRow: $0 + 1, inSection: 0) }, withRowAnimation: .None)
                        }
                        self?.tableView.endUpdates()
                    }
                    
                    self?.refreshControl.endRefreshing()
                },
                error: { [weak self] _ in
                    self?.refreshControl.endRefreshing()
                }
            )
            .start()
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.contentInset = UIEdgeInsetsZero
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.refreshNotification.notify(())
        
        updateNavbarAppear()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.Profile")
        
        headerTableViewCell?.viewModel.reloadModel()
        
        tabBarController?.delegate = self
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.Profile", properties: ["person_id": personID, "person_name" : headerTableViewCell!.viewModel.person.displayName])
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 280
        } else if items.isEmpty {
            return view.frame.height - 280
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section))
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("profile-header-cell") as! ProfileHeaderTableViewCell
            headerTableViewCell = cell
            cell.navigationController = navigationController as? NavigationController
            cell.bindViewModel(personID)
            return cell
        } else if items.isEmpty {
            let cell = tableView.dequeueReusableCellWithIdentifier("placeholder-cell") as! PlaceholderTableViewCell
            cell.textView.text = "Record your first Optograph"
            cell.iconView.text = String.iconWithName(.Rocket)
            return cell
        } else {
            return super.tableView(tableView, cellForRowAtIndexPath: NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section))
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.isEmpty ? 2 : items.count + 1
    }
    
    func pushCamera() {
        if StitchingService.isStitching() {
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last Optograph has finished rendering.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
        } else {
            let cameraViewController = CameraViewController()
            cameraViewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(cameraViewController, animated: false)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 1 && items.isEmpty {
            pushCamera()
        }
    }
    
}

// MARK: - UITabBarControllerDelegate
extension ProfileTableViewController: UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if viewController == navigationController {
            tableView.setContentOffset(CGPointZero, animated: true)
        }
    }
    
}

// MARK: - LoadMore
extension ProfileTableViewController: LoadMore {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        checkRow(indexPath) { [weak self] in
            self?.viewModel.loadMoreNotification.notify(())
        }
    }
    
}
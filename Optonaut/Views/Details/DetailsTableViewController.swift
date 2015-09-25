//
//  DetailsContainerView.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import Crashlytics
import Async
import CoreMotion

class DetailsTableViewController: UIViewController, BlackNavbar {
    
    private let viewModel: DetailsViewModel
    
    private let motionManager = CMMotionManager()
    
    // subviews
    private let topBarView = UIView()
    private let backButtonView = UIButton()
    private let tableView = UITableView()
    
    required init(optographId: UUID) {
        viewModel = DetailsViewModel(optographId: optographId)
        
        Answers.logContentViewWithName("Optograph Details \(optographId)",
            contentType: "OptographDetails",
            contentId: "optograph-details-\(optographId)",
            customAttributes: [:])
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topBarView.backgroundColor = .blackColor()
        view.addSubview(topBarView)
        
        backButtonView.setTitle(String.iconWithName(.Back), forState: .Normal)
        backButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        backButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        backButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "popViewController"))
        topBarView.addSubview(backButtonView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        
        tableView.registerClass(DetailsTableViewCell.self, forCellReuseIdentifier: "details-cell")
        tableView.registerClass(CommentTableViewCell.self, forCellReuseIdentifier: "comment-cell")
        tableView.registerClass(NewCommentTableViewCell.self, forCellReuseIdentifier: "new-cell")
        
        tableView.contentInset = UIEdgeInsets(top: 42, left: 0, bottom: 15, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -42)
        tableView.backgroundColor = .blackColor()
        view.insertSubview(tableView, atIndex: 0)
        
        viewModel.comments.producer.startWithNext { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
        
        motionManager.accelerometerUpdateInterval = 0.3
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        topBarView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 20)
        topBarView.autoPinEdge(.Left, toEdge: .Left, ofView: view)
        topBarView.autoPinEdge(.Right, toEdge: .Right, ofView: view)
        topBarView.autoSetDimension(.Height, toSize: 42)
        
        backButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 10)
        backButtonView.autoAlignAxis(.Horizontal, toSameAxisOfView: topBarView)
        
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        TabbarOverlayService.hidden = false
        TabbarOverlayService.contentOffsetTop = 42
        
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { accelerometerData, error in
            if let accelerometerData = accelerometerData {
                let x = accelerometerData.acceleration.x
                let y = accelerometerData.acceleration.y
                if self.viewModel.downloadProgress.value == 1 && abs(x) > abs(y) + 0.5 {
                    self.motionManager.stopAccelerometerUpdates()
                    let orientation: UIInterfaceOrientation = x > 0 ? .LandscapeLeft : .LandscapeRight
                    self.pushViewer(orientation)
                }
            }
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.motionManager.stopAccelerometerUpdates()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShowNotification:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHideNotification:", name: UIKeyboardWillHideNotification, object: nil)
        
        updateNavbarAppear()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        TabbarOverlayService.scrollOffsetTop = tableView.contentOffset.y + 62
        TabbarOverlayService.scrollOffsetBottom = tableView.contentSize.height - tableView.contentOffset.y - tableView.frame.height
    }
    
    func keyboardWillShowNotification(notification: NSNotification) {
        updateBottomLayoutConstraintWithNotification(notification, keyboardVisible: true)
    }
    
    func keyboardWillHideNotification(notification: NSNotification) {
        updateBottomLayoutConstraintWithNotification(notification, keyboardVisible: false)
    }
    
    func updateBottomLayoutConstraintWithNotification(notification: NSNotification, keyboardVisible: Bool) {
        let userInfo = notification.userInfo!
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let convertedKeyboardEndFrame = view.convertRect(keyboardEndFrame, fromView: view.window)
        let keyboardHeight = keyboardVisible ? CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) : 0
        let rawAnimationCurve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedIntValue << 16
        let animationCurve = UIViewAnimationOptions.init(rawValue: UInt(rawAnimationCurve))
        let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        let indexPath = NSIndexPath(forRow: 1, inSection: 0)
        
        // needs to be executed after table is refreshed
        Async.main {
            UIView.animateWithDuration(animationDuration,
                delay: 0,
                options: [.BeginFromCurrentState, animationCurve],
                animations: {
                    self.tableView.contentInset = UIEdgeInsets(top: 42, left: 0, bottom: keyboardHeight + 15, right: 0)
                    self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
                },
                completion: nil)
        }
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func popViewController() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        TabbarOverlayService.scrollOffsetTop = scrollView.contentOffset.y + 62
        TabbarOverlayService.scrollOffsetBottom = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.frame.height + 15
    }
    
    private func pushViewer(orientation: UIInterfaceOrientation = .LandscapeLeft) {
        if viewModel.downloadProgress.value == 1 {
            navigationController?.pushViewController(ViewerViewController(orientation: orientation, optograph: viewModel.optograph), animated: false)
            viewModel.increaseViewsCount()
        }
    }
    
}

// MARK: - UITableViewDelegate
extension DetailsTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            let imageHeight = view.frame.width * 7 / 8
            let barHeight: CGFloat = 42
            let textHeight = calcTextHeight(viewModel.optograph.text, withWidth: view.frame.width - 38, andFont: .robotoOfSize(13, withType: .Regular)) + 24
            let spacing: CGFloat = 20
            return imageHeight + barHeight + textHeight + spacing
        } else if indexPath.row == 1 {
            return 40
        } else {
            let textWidth = view.frame.width - 38 - 41
            let textHeight = calcTextHeight(viewModel.comments.value[indexPath.row - 2].text, withWidth: textWidth, andFont: .robotoOfSize(12, withType: .Light))
            let restHeight: CGFloat = 30 // includes name and spacing
            return restHeight + textHeight
        }
    }
    
}

// MARK: - UITableViewDataSource
extension DetailsTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("details-cell") as! DetailsTableViewCell
            cell.viewModel = viewModel
            cell.navigationController = navigationController as? NavigationController
            cell.bindViewModel()
            return cell
        } else if indexPath.row == 1 {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("new-cell") as! NewCommentTableViewCell
            cell.bindViewModel(viewModel.optograph.id, commentsCount: viewModel.commentsCount.value)
            cell.postCallback = { [weak self] comment in
                self?.viewModel.insertNewComment(comment)
            }
            return cell
        } else {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("comment-cell") as! CommentTableViewCell
            cell.navigationController = navigationController as? NavigationController
            cell.bindViewModel(viewModel.comments.value[indexPath.row - 2])
            return cell
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.comments.value.count + 2
    }
    
}
//
//  CommentTableViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import PureLayout_iOS

class CommentTableViewController: UIViewController, TransparentNavbar {
    
    private let viewModel: CommentsViewModel
    
    // subviews
    private let tableView = UITableView()
    private let blankHeaderView = UIView()
    
    var scrollCallback: ((CGFloat) -> ())?
    
    required init(optographId: Int) {
        viewModel = CommentsViewModel(optographId: optographId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: nil, action: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        
        tableView.registerClass(CommentTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.registerClass(NewCommentTableViewCell.self, forCellReuseIdentifier: "new-cell")
        view.addSubview(tableView)
        
        blankHeaderView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 480)
        tableView.tableHeaderView = blankHeaderView
        
        viewModel.results.producer.start(next: { _ in
            self.tableView.reloadData()
        })
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
        
        let indexPath = NSIndexPath(forRow: viewModel.results.value.count, inSection: 0)
        
        UIView.animateWithDuration(animationDuration,
            delay: 0,
            options: [.BeginFromCurrentState, animationCurve],
            animations: {
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
                self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
            },
            completion: nil)
    }
    
    override func updateViewConstraints() {
        tableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        super.updateViewConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.contentInset = UIEdgeInsetsZero
    }
    
}

// MARK: - UITableViewDelegate
extension CommentTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row < viewModel.results.value.count {
            return 60
        } else {
            return 52
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollCallback?(tableView.contentOffset.y)
    }
    
}

// MARK: - UITableViewDataSource
extension CommentTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row < viewModel.results.value.count {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as! CommentTableViewCell
            cell.navigationController = navigationController
            cell.bindViewModel(viewModel.results.value[indexPath.row])
            return cell
        } else {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("new-cell") as! NewCommentTableViewCell
            cell.bindViewModel(viewModel.optographId.value)
            return cell
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.results.value.count + 1
    }
    
}
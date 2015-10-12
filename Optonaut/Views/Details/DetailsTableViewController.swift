//
//  DetailsContainerView.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/14/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import Mixpanel
import Async
import SceneKit
import WebImage
import ReactiveCocoa

class CombinedMotionManager: RotationMatrixSource {
    private var horizontalOffset: Float = 0
    
    func addHorizontalOffset(offset: Float) {
        horizontalOffset += offset
    }
    
    func getRotationMatrix() -> GLKMatrix4 {
        let offsetRotation = GLKMatrix4MakeZRotation(horizontalOffset / 250)
        return GLKMatrix4Multiply(offsetRotation, MotionService.sharedInstance.getRotationMatrix())
    }
}

class DetailsTableViewController: UIViewController, NoNavbar {
    
    private let viewModel: DetailsViewModel
    
    private var combinedMotionManager = CombinedMotionManager()
    
    // subviews
    private let tableView = TableView()
    private let blurView = OffsetBlurView()
    
    private var renderDelegate: StereoRenderDelegate!
    private var scnView: SCNView!
    
    required init(optographId: UUID) {
        viewModel = DetailsViewModel(optographId: optographId)
        
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
        
        view.backgroundColor = .blackColor()
        
        navigationItem.title = ""
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        scnView = SCNView(frame: view.frame)
        
        renderDelegate = StereoRenderDelegate(rotationMatrixSource: combinedMotionManager, width: scnView.frame.width, height: scnView.frame.height, fov: 65)
        
        scnView.scene = renderDelegate.scene
        scnView.delegate = renderDelegate
        scnView.backgroundColor = .clearColor()
        
        view.addSubview(scnView)
        
        let queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
        SDWebImageManager.sharedManager().downloadImageForURL(viewModel.optograph.leftTextureAssetURL)
            .observeOn(QueueScheduler(queue: queue))
            .startWithNext { [weak self] image in
                self?.renderDelegate.image = image
                self?.scnView.prepareObject(self!.renderDelegate!.scene, shouldAbortBlock: nil)
                self?.scnView.playing = true
        }
        
        tableView.backgroundColor = .clearColor()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        tableView.canCancelContentTouches = false
        tableView.delaysContentTouches = false
        tableView.exclusiveTouch = false
        
        tableView.horizontalScrollDistanceCallback = { [weak self] offset in
            self?.combinedMotionManager.addHorizontalOffset(offset)
        }
        
        tableView.registerClass(DetailsTableViewCell.self, forCellReuseIdentifier: "details-cell")
        tableView.registerClass(CommentTableViewCell.self, forCellReuseIdentifier: "comment-cell")
        tableView.registerClass(NewCommentTableViewCell.self, forCellReuseIdentifier: "new-cell")
        tableView.frame = view.frame
        tableView.scrollEnabled = true
        view.addSubview(tableView)
        
        tableView.backgroundView = blurView
        
        viewModel.comments.producer.startWithNext { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.OptographDetails")
        
        MotionService.sharedInstance.rotateEnable { [weak self] orientation in
            switch orientation {
            case .LandscapeLeft, .LandscapeRight:
                self?.pushViewer(orientation)
            default: break
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.OptographDetails", properties: ["optograph_id": viewModel.optograph.id])
        
        MotionService.sharedInstance.motionSlow()
        MotionService.sharedInstance.rotateDisable()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        MotionService.sharedInstance.motionFast()
        
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
        
        let offset = view.frame.height - 78
        tableView.contentInset = UIEdgeInsets(top: offset, left: 0, bottom: tabBarController!.tabBar.frame.height, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -offset)
//        tableView.contentOffset = CGPoint(x: 0, y: 75)
    }
    
    func keyboardWillShowNotification(notification: NSNotification) {
//        updateBottomLayoutConstraintWithNotification(notification, keyboardVisible: true)
    }
    
    func keyboardWillHideNotification(notification: NSNotification) {
//        updateBottomLayoutConstraintWithNotification(notification, keyboardVisible: false)
    }
    
    func updateBottomLayoutConstraintWithNotification(notification: NSNotification, keyboardVisible: Bool) {
        let userInfo = notification.userInfo!
        let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let convertedKeyboardEndFrame = view.convertRect(keyboardEndFrame, fromView: view.window)
        let keyboardHeight = keyboardVisible ? CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) : 0
        let rawAnimationCurve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedIntValue << 16
        let animationCurve = UIViewAnimationOptions.init(rawValue: UInt(rawAnimationCurve))
        let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        let indexPath = NSIndexPath(forRow: viewModel.comments.value.count + 1, inSection: 0)
        
        // needs to be executed after table is refreshed
        Async.main {
            UIView.animateWithDuration(animationDuration,
                delay: 0,
                options: [.BeginFromCurrentState, animationCurve],
                animations: {
                    self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
                    self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
                },
                completion: nil)
        }
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func pushViewer(orientation: UIInterfaceOrientation = .LandscapeLeft) {
        navigationController?.pushViewController(ViewerViewController(orientation: orientation, optograph: viewModel.optograph, distortion: .VROne), animated: false)
        viewModel.increaseViewsCount()
    }
    
}

// MARK: - UITableViewDelegate
extension DetailsTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            let infoHeight = CGFloat(78)
            let textWidth = view.frame.width - 40
            let textHeight = calcTextHeight(viewModel.text.value, withWidth: textWidth, andFont: UIFont.textOfSize(14, withType: .Regular))
            let restHeight = CGFloat(20)
            return textHeight + restHeight + infoHeight
        } else if indexPath.row == 1 {
            return 60
        } else {
            let textWidth = view.frame.width - 38 - 41
            let textHeight = calcTextHeight(viewModel.comments.value[indexPath.row - 2].text, withWidth: textWidth, andFont: UIFont.textOfSize(13, withType: .Regular))
            let restHeight = CGFloat(40) // includes name and spacing
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

private class TableView: UITableView {
    
    var horizontalScrollDistanceCallback: ((Float) -> ())?
    
    private override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        
        if let touch = touches.first {
            let oldPoint = touch.previousLocationInView(self)
            let newPoint = touch.locationInView(self)
            self.horizontalScrollDistanceCallback?(Float(newPoint.x - oldPoint.x))
        }
    }
    
}

private class OffsetBlurView: UIView {
    
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    
    override var frame: CGRect {
        didSet {
            blurView.frame = CGRect(x: 0, y: -frame.origin.y, width: frame.width, height: frame.height + frame.origin.y)
        }
    }
    
    init() {
        super.init(frame: CGRectZero)
        addSubview(blurView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
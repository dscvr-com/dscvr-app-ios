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
import CoreMotion
import SceneKit

class CombinedMotionManager: RotationMatrixSource {
    private let motionManager: CMMotionManager
    private var horizontalOffset: Float = 0
    
    init(motionManager: CMMotionManager) {
        self.motionManager = motionManager
    }
    
    func addHorizontalOffset(offset: Float) {
        horizontalOffset += offset
    }
    
    func getRotationMatrix() -> GLKMatrix4 {
        guard let r = motionManager.deviceMotion?.attitude.rotationMatrix else {
            return GLKMatrix4Make(1, 0, 0, 0,
                                  0, 0, 1, 0,
                                  0, 1, 0, 0,
                                  0, 0, 0, 1)
        }
        
        let mat = GLKMatrix4Make(
            Float(r.m11), Float(r.m12), Float(r.m13), 0,
            Float(r.m21), Float(r.m22), Float(r.m23), 0,
            Float(r.m31), Float(r.m32), Float(r.m33), 0,
            0,            0,            0,            1
        )
        
        let rot = GLKMatrix4MakeZRotation(horizontalOffset / 150)
        
        return GLKMatrix4Multiply(rot, mat)
    }
}

class DetailsTableViewController: UIViewController, NoNavbar {
    
    private let viewModel: DetailsViewModel
    
    private var combinedMotionManager = CombinedMotionManager(motionManager: CMMotionManager())
    
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
        
        navigationItem.title = ""
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: view.frame, options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
        } else {
            scnView = SCNView(frame: view.frame)
        }
        
        scnView.backgroundColor = .blackColor()
        scnView.playing = true
        
        view.addSubview(scnView)
        
        viewModel.downloadProgress.producer
            .filter { $0 == 1 }
            .startWithNext { [weak self] _ in
                self?.renderSphere()
            }
        
//        tableView.backgroundColor = UIColor.whiteColor().alpha(0.5)
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
        
        combinedMotionManager.motionManager.accelerometerUpdateInterval = 0.3
    }
    
    func renderSphere() {
        renderDelegate = StereoRenderDelegate(eye: .Left, optograph: viewModel.optograph, rotationMatrixSource: combinedMotionManager, width: scnView.frame.width, height: scnView.frame.height, fov: 85)
        
        scnView.scene = renderDelegate.root
        scnView.delegate = renderDelegate
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.OptographDetails")
        
        combinedMotionManager.motionManager.startDeviceMotionUpdates()
        combinedMotionManager.motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { accelerometerData, error in
            if let accelerometerData = accelerometerData {
                let x = accelerometerData.acceleration.x
                let y = accelerometerData.acceleration.y
                if self.viewModel.downloadProgress.value == 1 && -x > abs(y) + 0.5 {
                    self.combinedMotionManager.motionManager.stopAccelerometerUpdates()
                    let orientation: UIInterfaceOrientation = x > 0 ? .LandscapeLeft : .LandscapeRight
                    self.pushViewer(orientation)
                }
            }
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.OptographDetails", properties: ["optograph_id": viewModel.optograph.id])
        
        combinedMotionManager.motionManager.stopAccelerometerUpdates()
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
        if viewModel.downloadProgress.value == 1 {
            navigationController?.pushViewController(ViewerViewController(orientation: orientation, optograph: viewModel.optograph, distortion: .VROne), animated: false)
            viewModel.increaseViewsCount()
        }
    }
    
}

// MARK: - UITableViewDelegate
extension DetailsTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 78
        } else if indexPath.row <= viewModel.comments.value.count {
            let textWidth = view.frame.width - 38 - 41
            let textHeight = calcTextHeight(viewModel.comments.value[indexPath.row - 1].text, withWidth: textWidth)
            let restHeight = CGFloat(40) // includes name and spacing
            return restHeight + textHeight
        } else {
            return 60
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
        } else if indexPath.row <= viewModel.comments.value.count {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("comment-cell") as! CommentTableViewCell
            cell.navigationController = navigationController as? NavigationController
            cell.bindViewModel(viewModel.comments.value[indexPath.row - 1])
            return cell
        } else {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("new-cell") as! NewCommentTableViewCell
            cell.bindViewModel(viewModel.optograph.id)
            cell.postCallback = { [weak self] comment in
                self?.viewModel.insertNewComment(comment)
            }
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
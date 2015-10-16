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
    private let parent: RotationMatrixSource
    
    init(parent: RotationMatrixSource) {
        self.parent = parent
    }
    
    func addHorizontalOffset(offset: Float) {
        horizontalOffset += offset
    }
    
    func getRotationMatrix() -> GLKMatrix4 {
        let offsetRotation = GLKMatrix4MakeZRotation(horizontalOffset / 250)
        return GLKMatrix4Multiply(offsetRotation, parent.getRotationMatrix())
    }
}

class DetailsTableViewController: UIViewController, NoNavbar {
    
    private let viewModel: DetailsViewModel
    
    private let combinedMotionManager = CombinedMotionManager(parent: CoreMotionRotationSource.Instance)
    
    // subviews
    private let tableView = TableView()
    private let blurView = OffsetBlurView()
    private let glassesButtonView = ActionButton()
    private let loadingView = UIActivityIndicatorView()
    
    private var renderDelegate: StereoRenderDelegate!
    private var scnView: SCNView!
    
    private var rotationDisposable: Disposable?
    private var downloadDisposable: Disposable?
    
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
        glassesButtonView.setTitle(String.iconWithName(.Cardboard), forState: .Normal)
        glassesButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        glassesButtonView.defaultBackgroundColor = .Accent
        glassesButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        glassesButtonView.layer.cornerRadius = 30
        glassesButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showRotationAlert"))
        glassesButtonView.frame = CGRect(x: view.frame.width - 80, y: view.frame.height - 80 - 78 - tabBarController!.tabBar.frame.height, width: 60, height: 60)
        view.addSubview(glassesButtonView)
        
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
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - tabBarController!.tabBar.frame.height)
        tableView.scrollEnabled = true
        view.addSubview(tableView)
        
        loadingView.activityIndicatorViewStyle = .WhiteLarge
        loadingView.startAnimating()
        loadingView.frame = CGRect(x: view.frame.width / 2 - 20, y: view.frame.height / 2 - 20 - 78 / 2, width: 40, height: 40)
        view.addSubview(loadingView)
        
        tableView.backgroundView = blurView
        
        viewModel.comments.producer.startWithNext { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "dismissKeyboard"))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.OptographDetails")
        
        loadTexture()

    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.OptographDetails", properties: ["optograph_id": viewModel.optograph.id])
        
        unloadTexture()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        CoreMotionRotationSource.Instance.start()
        RotationService.sharedInstance.rotationEnable()
        
        rotationDisposable = RotationService.sharedInstance.rotationSignal?
            .skipRepeats()
            .observeOn(UIScheduler())
            .observeNext { [weak self] orientation in
                switch orientation {
                case .LandscapeLeft, .LandscapeRight:
                    self?.pushViewer(orientation)
                default: break
                }
        }

        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        updateNavbarAppear()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        rotationDisposable?.dispose()
        
        CoreMotionRotationSource.Instance.stop()
        RotationService.sharedInstance.rotationDisable()
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.contentOffset = CGPoint(x: 0, y: -(tableView.frame.height - 78))
        tableView.contentInset = UIEdgeInsets(top: tableView.frame.height - 78, left: 0, bottom: 10, right: 0)
    }
    
    private func loadTexture() {
        downloadDisposable = SDWebImageManager.sharedManager().downloadImageForURL(viewModel.optograph.leftTextureAssetURL)
            .startWithNext { [weak self] image in
                if let _self = self {
                    _self.renderDelegate.image = image
                    _self.scnView.prepareObject(_self.renderDelegate!.scene, shouldAbortBlock: nil)
                    _self.scnView.playing = true
                    _self.downloadDisposable = nil
                    _self.loadingView.stopAnimating()
                    _self.loadingView.hidden = true
                    _self.blurView.fullscreen = false
                }
            }
    }
    
    private func unloadTexture() {
        downloadDisposable?.dispose()
        self.renderDelegate.image = nil
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsets(top: tableView.frame.height - 78, left: 0, bottom: 10, right: 0)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func pushViewer(orientation: UIInterfaceOrientation) {
        navigationController?.pushViewController(ViewerViewController(orientation: orientation, optograph: viewModel.optograph), animated: false)
        viewModel.increaseViewsCount()
    }
    
    func showRotationAlert() {
        let alert = UIAlertController(title: "Rotate counter clockwise", message: "Please rotate your phone counter clockwise by 90 degree.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        self.navigationController?.presentViewController(alert, animated: true, completion: nil)
    }
    
}

// MARK: - UITableViewDelegate
extension DetailsTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            let infoHeight = CGFloat(78)
            let textWidth = view.frame.width - 40
            let textHeight = calcTextHeight(viewModel.text.value, withWidth: textWidth, andFont: UIFont.textOfSize(14, withType: .Regular)) + 20
            let hashtagsHeight = calcTextHeight(viewModel.hashtags.value, withWidth: textWidth, andFont: UIFont.textOfSize(14, withType: .Semibold)) + 25
            return textHeight + hashtagsHeight + infoHeight
        } else if indexPath.row == 1 {
            return 60
        } else {
            let textWidth = view.frame.width - 40 - 40 - 20 - 30 - 20
            let textHeight = calcTextHeight(viewModel.comments.value[indexPath.row - 2].text, withWidth: textWidth, andFont: UIFont.textOfSize(13, withType: .Regular)) + 15
            return max(textHeight, 60)
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
            cell.delegate = self
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


// MARK: - NewCommentTableViewDelegate
extension DetailsTableViewController: NewCommentTableViewDelegate {
    func newCommentAdded(comment: Comment) {
        self.viewModel.insertNewComment(comment)
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
    
    private override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        // this took a lot of time. don't bother to understand this
        if frame.height + contentOffset.y - 78 < 80 && point.y < 0 && frame.width - point.x < 100 {
            return false
        }
        return true
    }
    
}

private class OffsetBlurView: UIView {
    
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    
    var fullscreen = true {
        didSet {
            updateBlurViewFrame()
        }
    }
    
    override var frame: CGRect {
        didSet {
            updateBlurViewFrame()
        }
    }
    
    init() {
        super.init(frame: CGRectZero)
        addSubview(blurView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateBlurViewFrame() {
        if fullscreen {
            blurView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        } else {
            blurView.frame = CGRect(x: 0, y: -frame.origin.y, width: frame.width, height: frame.height + frame.origin.y)
        }
    }
    
}
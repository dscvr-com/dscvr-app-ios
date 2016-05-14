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
import ReactiveCocoa
import Kingfisher
import SpriteKit

let queue1 = dispatch_queue_create("detail_view", DISPATCH_QUEUE_SERIAL)

class DetailsTableViewController: UIViewController, NoNavbar,TabControllerDelegate{
    
    //private let viewModel: DetailsViewModel
    
    
    private var combinedMotionManager: CombinedMotionManager!
    // subviews
    private let tableView = TableView()
    
    private var renderDelegate: CubeRenderDelegate!
    private var scnView: SCNView!
    
    private var imageDownloadDisposable: Disposable?
    
    private var rotationAlert: UIAlertController?
    
    private enum LoadingStatus { case Nothing, Preview, Loaded }
    private let loadingStatus = MutableProperty<LoadingStatus>(.Nothing)
    let imageCache: CollectionImageCache
    
    var optographId:UUID = ""
    var cellIndexpath:Int = 0
    
    var direction: Direction {
        set(direction) {
            combinedMotionManager.setDirection(direction)
        }
        get {
            return combinedMotionManager.getDirection()
        }
    }
    
    private var touchStart: CGPoint?
    
    required init() {
        //viewModel = DetailsViewModel(optographID: optographID)
        let textureSize = getTextureWidth(UIScreen.mainScreen().bounds.width, hfov: HorizontalFieldOfView)
        imageCache = CollectionImageCache(textureSize: textureSize)
        
        logInit()
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
        
        
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: self.view.frame, options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
        } else {
            scnView = SCNView(frame: self.view.frame)
        }
        
        let hfov: Float = 35
        combinedMotionManager = CombinedMotionManager(sceneSize: scnView.frame.size, hfov: hfov)
        renderDelegate = CubeRenderDelegate(rotationMatrixSource: combinedMotionManager, width: scnView.frame.width, height: scnView.frame.height, fov: Double(hfov), cubeFaceCount: 2, autoDispose: true)
        renderDelegate.scnView = scnView
        scnView.scene = renderDelegate.scene
        scnView.delegate = renderDelegate
        scnView.backgroundColor = .clearColor()
        scnView.hidden = false
        self.view.addSubview(scnView)
        
//        viewModel.comments.producer.startWithNext { [weak self] _ in
//            self?.tableView.reloadData()
//        }
        
        self.willDisplay()
        let cubeImageCache = imageCache.get(cellIndexpath, optographID: optographId, side: .Left)
        self.setCubeImageCache(cubeImageCache)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.OptographDetails")
        tabController!.delegate = self
        
        //viewModel.viewIsActive.value = true
        
//        if let rotationSignal = RotationService.sharedInstance.rotationSignal {
//            self.viewModel.isLoading.producer.startWithSignal { isLoadingSignal, disposable in
//                isLoadingSignal.combineLatestWith(rotationSignal)
//                    //.filter { (isLoading, _) in return !isLoading } // Uncomment this line to only allow invoking the viewer when loading is finished
//                    .map { (_, rotation) in return rotation }
//                    .skipRepeats()
//                    .filter([.LandscapeLeft, .LandscapeRight])
//                    .takeWhile { [weak self] _ in self?.viewModel.viewIsActive.value ?? false }
//                    .take(1)
//                    .observeOn(UIScheduler())
//                    .observeNext { [weak self] orientation in self?.pushViewer(orientation) }
//            }
//        }
        
//        viewModel.optographReloaded.producer.startWithNext { [weak self] in
//            if self?.viewModel.optograph.deletedAt != nil {
//                self?.navigationController?.popViewControllerAnimated(false)
//            }
//        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        let point = touches.first!.locationInView(scnView)
        touchStart = point
        
        if touches.count == 1 {
            combinedMotionManager.touchStart(point)
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        let point = touches.first!.locationInView(scnView)
        
        combinedMotionManager.touchMove(point)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        _ = touchStart!.distanceTo(touches.first!.locationInView(self.view))
        super.touchesEnded(touches, withEvent: event)
        if touches.count == 1 {
            combinedMotionManager.touchEnd()
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        if let touches = touches where touches.count == 1 {
            combinedMotionManager.touchEnd()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        //Mixpanel.sharedInstance().track("View.OptographDetails", properties: ["optograph_id": viewModel.optograph.ID, "optograph_description" : viewModel.optograph.text])
        Mixpanel.sharedInstance().track("View.OptographDetails", properties: ["optograph_id": "", "optograph_description" : ""])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
        tabController!.hideUI()
        tabController!.disableScrollView()
        
        CoreMotionRotationSource.Instance.start()
        RotationService.sharedInstance.rotationEnable()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DetailsTableViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DetailsTableViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        updateNavbarAppear()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //viewModel.viewIsActive.value = false
        imageDownloadDisposable?.dispose()
        imageDownloadDisposable = nil
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
    func getVisibleAndAdjacentPlaneIndices(direction: Direction) -> [CubeImageCache.Index] {
        let rotation = phiThetaToRotationMatrix(direction.phi, theta: direction.theta)
        return renderDelegate.getVisibleAndAdjacentPlaneIndicesFromRotationMatrix(rotation)
    }
    
    func setCubeImageCache(cache: CubeImageCache) {
        
        renderDelegate.nodeEnterScene = nil
        renderDelegate.nodeLeaveScene = nil
        
        renderDelegate.reset()
        
        renderDelegate.nodeEnterScene = { [weak self] index in
            dispatch_async(queue1) {
                cache.get(index) { [weak self] (texture: SKTexture, index: CubeImageCache.Index) in
                    self?.renderDelegate.setTexture(texture, forIndex: index)
                    Async.main { [weak self] in
                        self?.loadingStatus.value = .Loaded
                    }
                }
            }
        }
        
        renderDelegate.nodeLeaveScene = { index in
            dispatch_async(queue1) {
                cache.forget(index)
            }
        }
    }
    
    func willDisplay() {
        scnView.playing = UIDevice.currentDevice().deviceType != .Simulator
    }
    
    func didEndDisplay() {
        scnView.playing = false
        combinedMotionManager.reset()
        loadingStatus.value = .Nothing
        renderDelegate.reset()
    }
    
    func forgetTextures() {
        renderDelegate.reset()
    }
//    private func pushViewer(orientation: UIInterfaceOrientation) {
//        rotationAlert?.dismissViewControllerAnimated(true, completion: nil)
//        let viewerViewController = ViewerViewController(orientation: orientation, optograph: viewModel.optograph)
//        viewerViewController.hidesBottomBarWhenPushed = true
//        navigationController?.pushViewController(viewerViewController, animated: false)
//        viewModel.increaseViewsCount()
//    }
    
    func showRotationAlert() {
        rotationAlert = UIAlertController(title: "Rotate counter clockwise", message: "Please rotate your phone counter clockwise by 90 degree.", preferredStyle: .Alert)
        rotationAlert!.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
        self.navigationController?.presentViewController(rotationAlert!, animated: true, completion: nil)
    }
    
}

// MARK: - UITableViewDelegate
extension DetailsTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        let superView = tableView!.superview!
        if indexPath.row == 0 {
            let yOffset = max(0, tableView.frame.height - tableView.contentSize.height)
            UIView.animateWithDuration(0.2, delay: 0, options: [.BeginFromCurrentState],
                animations: {
                    self.tableView.contentOffset = CGPoint(x: 0, y: -yOffset)
                },
                completion: nil)
        }
    }
    
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        if indexPath.row == 0 {
//            let infoHeight = CGFloat(78)
//            let textWidth = view.frame.width - 40
//            let textHeight = calcTextHeight(viewModel.text.value, withWidth: textWidth, andFont: UIFont.textOfSize(14, withType: .Regular)) + 20
//            let hashtagsHeight = calcTextHeight(viewModel.hashtags.value, withWidth: textWidth, andFont: UIFont.textOfSize(14, withType: .Semibold)) + 25
//            return textHeight + hashtagsHeight + infoHeight
//        } else if indexPath.row == 1 {
//            return 60
//        } else {
//            let textWidth = view.frame.width - 40 - 40 - 20 - 30 - 20
//            let textHeight = calcTextHeight(viewModel.comments.value[indexPath.row - 2].text, withWidth: textWidth, andFont: UIFont.textOfSize(13, withType: .Regular)) + 15
//            return max(textHeight, 60)
//        }
//    }
    
}

//// MARK: - UITableViewDataSource
//extension DetailsTableViewController: UITableViewDataSource {
//    
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        if indexPath.row == 0 {
//            let cell = self.tableView.dequeueReusableCellWithIdentifier("details-cell") as! DetailsTableViewCell
//            cell.viewModel = viewModel
//            cell.navigationController = navigationController as? NavigationController
//            cell.bindViewModel()
//            return cell
//        } else if indexPath.row == 1 {
//            let cell = self.tableView.dequeueReusableCellWithIdentifier("new-cell") as! NewCommentTableViewCell
//            cell.bindViewModel(viewModel.optograph.ID, commentsCount: viewModel.commentsCount.value)
//            cell.navigationController = navigationController as? NavigationController
//            cell.delegate = self
//            return cell
//        } else {
//            let cell = self.tableView.dequeueReusableCellWithIdentifier("comment-cell") as! CommentTableViewCell
//            cell.navigationController = navigationController as? NavigationController
//            cell.bindViewModel(viewModel.comments.value[indexPath.row - 2])
//            return cell
//        }
//    }
//    
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return viewModel.comments.value.count + 2
//    }
//    
//}
//
//
//// MARK: - NewCommentTableViewDelegate
//extension DetailsTableViewController: NewCommentTableViewDelegate {
//    func newCommentAdded(comment: Comment) {
//        self.viewModel.insertNewComment(comment)
//    }
//}

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
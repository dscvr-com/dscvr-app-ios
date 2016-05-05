//
//  SwipeViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 4/29/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import EZSwipeController
import UIKit
import ReactiveCocoa
import Async
import Icomoon
import SwiftyUserDefaults
import Result

class SwipeViewController: EZSwipeController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    var viewOffset:CGFloat = 0
    
    private let uiWrapper = PassThroughView()
    let cameraButton = RecordButton()
    let leftButton = TabButton()
    let rightButton = TabButton()
    
    var imageView: UIImageView!
    var imagePicker = UIImagePickerController()
    
    private let bottomGradient = CAGradientLayer()
    let bottomGradientOffset = MutableProperty<CGFloat>(126)
    let isThetaImage = MutableProperty<Bool>(false)
    
    var delegate: TabControllerDelegate?
    
    private var uiHidden = false
    private var uiLocked = false

    override func setupView() {
        datasource = self
        view.backgroundColor = UIColor.clearColor()
        
        bottomGradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().alpha(0.5).CGColor]
        uiWrapper.layer.addSublayer(bottomGradient)
        
        let width = view.frame.width
        
        bottomGradientOffset.producer.startWithNext { [weak self] offset in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            //            CATransaction.setAnimationDuration(0.3)
            //            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            self?.bottomGradient.frame = CGRect(x: 0, y: 0, width: width, height: offset)
            CATransaction.commit()
        }
        cameraButton.frame = CGRect(x: view.frame.width / 2 - 35, y: 126 / 2 - 35, width: 70, height: 70)
        cameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SwipeViewController.tapCameraButton)))
        cameraButton.addTarget(self, action: #selector(SwipeViewController.touchStartCameraButton), forControlEvents: [.TouchDown])
        cameraButton.addTarget(self, action: #selector(SwipeViewController.touchEndCameraButton), forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
        uiWrapper.addSubview(cameraButton)
        
        PipelineService.stitchingStatus.producer
            .observeOnMain()
            .startWithNext { [weak self] status in
                switch status {
                case .Uninitialized:
                    self?.cameraButton.loading = true
                case .Idle:
                    self?.cameraButton.progress = nil
                    if self?.cameraButton.progressLocked == false {
                        self?.cameraButton.icon = UIImage(named:"camera_icn")!
                        self?.rightButton.loading = false
                    }
                case let .Stitching(progress):
                    self?.cameraButton.progress = CGFloat(progress)
                case .StitchingFinished(_):
                    self?.cameraButton.progress = nil
                }
        }
        
        let buttonSpacing = (view.frame.width / 2 - 35) / 2 - 14
        leftButton.frame = CGRect(x: buttonSpacing, y: 126 / 2 - 23.5, width: 28, height: 28)
        leftButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SwipeViewController.tapLeftButton)))
        uiWrapper.addSubview(leftButton)
        
        rightButton.frame = CGRect(x: view.frame.width - buttonSpacing - 28, y: 126 / 2 - 23.5, width: 28, height: 28)
        rightButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SwipeViewController.tapRightButton)))
        uiWrapper.addSubview(rightButton)
        
        //initNotificationIndicator()
        
        PipelineService.checkStitching()
        PipelineService.checkUploading()
        
        uiWrapper.frame = CGRect(x: 0, y: view.frame.height - 126, width: view.frame.width, height: 126)
        view.addSubview(uiWrapper)
        
        imagePicker.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        isThetaImage.producer
            .filter(isTrue)
            .startWithNext{ _ in
                let alert = UIAlertController(title: "Ooops!", message: "Not a Theta Image, Please choose another photo", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{ _ in
                    self.isThetaImage.value = false
                }))
                self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func openGallary() {
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.navigationBar.translucent = false
        imagePicker.navigationBar.barTintColor = UIColor.Accent
        imagePicker.navigationBar.setTitleVerticalPositionAdjustment(0, forBarMetrics: .Default)
        imagePicker.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.displayOfSize(15, withType: .Semibold),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        imagePicker.setNavigationBarHidden(false, animated: false)
        imagePicker.interactivePopGestureRecognizer?.enabled = false
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    func uploadTheta(thetaImage:UIImage) {
        
        let createOptographViewController = SaveThetaViewController(thetaImage:thetaImage)
        
        createOptographViewController.hidesBottomBarWhenPushed = true
        
        navigationController?.pushViewController(createOptographViewController, animated: false)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if pickedImage.size.height == 2688 && pickedImage.size.width == 5376 {
                uploadTheta(pickedImage)
            } else {
                isThetaImage.value = true
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showUI() {
        if !uiLocked {
            uiWrapper.hidden = false
        }
    }
    
    func hideUI() {
        if !uiLocked {
            uiWrapper.hidden = true
        }
    }
    
    func lockUI() {
        uiLocked = true
    }
    
    func unlockUI() {
        uiLocked = false
    }
    
    dynamic private func showCardboardAlert() {
        let confirmAlert = UIAlertController(title: "Put phone in VR viewer", message: "Please turn your phone and put it into your VR viewer.", preferredStyle: .Alert)
        confirmAlert.addAction(UIAlertAction(title: "Continue", style: .Cancel, handler: { _ in return }))
        navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
    }
    
    dynamic private func tapLeftButton() {
        delegate?.onTapLeftButton()
    }
    
    dynamic private func tapRightButton() {
        delegate?.onTapRightButton()
    }
    
    dynamic private func tapCameraButton() {
        delegate?.onTapCameraButton()
    }
    
    dynamic private func touchStartCameraButton() {
        delegate?.onTouchStartCameraButton()
    }
    
    dynamic private func touchEndCameraButton() {
        delegate?.onTouchEndCameraButton()
    }
}

class RecordButton: UIButton {
    
    private var touched = false
    
    private let progressLayer = CALayer()
    private let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    
    var icon: UIImage = UIImage(named:"camera_icn")! {
        didSet {
            //setTitle(String.iconWithName(icon), forState: .Normal)
            setImage(icon, forState: UIControlState.Normal)
        }
    }
    
    var iconColor: UIColor = .whiteColor() {
        didSet {
            setTitleColor(iconColor.alpha(loading ? 0 : 1), forState: .Normal)
        }
    }
    
    var loading = false {
        didSet {
            if loading {
                loadingView.startAnimating()
            } else {
                loadingView.stopAnimating()
            }
            
            setTitleColor(titleColorForState(.Normal)!.alpha(loading ? 0 : 1), forState: .Normal)
            
            userInteractionEnabled = !loading
        }
    }
    
    var progressLocked = false {
        didSet {
            if !progressLocked {
                // reapply last progress value
                let tmp = progress
                progress = tmp
            }
        }
    }
    
    var progress: CGFloat? = nil {
        didSet {
            if !progressLocked {
                if let progress = progress {
                    backgroundColor = UIColor.Accent.mixWithColor(.blackColor(), amount: 0.3).alpha(0.5)
                    loading = progress != 1
                } else {
                    backgroundColor = .Clear
                    loading = false
                }
                
                layoutSubviews()
            }
        }
    }
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        progressLayer.backgroundColor = UIColor.Accent.CGColor
        layer.addSublayer(progressLayer)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        backgroundColor = .Clear
        clipsToBounds = true
        
        layer.cornerRadius = 12
        
        setTitleColor(.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.iconOfSize(33)
        
        addTarget(self, action: #selector(RecordButton.buttonTouched), forControlEvents: .TouchDown)
        addTarget(self, action: #selector(RecordButton.buttonUntouched), forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        progressLayer.frame = CGRect(x: 0, y: 0, width: frame.width * (progress ?? 0), height: frame.height)
        loadingView.fillSuperview()
    }
    
    private func updateBackground() {
        if touched {
            backgroundColor = .Clear
        } else {
            backgroundColor = .Clear
        }
    }
    
    dynamic private func buttonTouched() {
        touched = true
        updateBackground()
    }
    
    dynamic private func buttonUntouched() {
        touched = false
        updateBackground()
    }
}

class TabButton: UIButton {
    
    enum Color { case Light, Dark }
    
    var title: String = "" {
        didSet {
            text.text = title
        }
    }
    
    var icon: Icon = .Cancel {
        didSet {
            setTitle(String.iconWithName(icon), forState: .Normal)
        }
    }
    
    var color: Color = .Dark {
        didSet {
            let actualColor = color == .Dark ? .whiteColor() : UIColor(0x919293)
            setTitleColor(actualColor, forState: .Normal)
            text.textColor = actualColor
            loadingView.color = actualColor
        }
    }
    
    var loading = false {
        didSet {
            if loading {
                loadingView.startAnimating()
            } else {
                loadingView.stopAnimating()
            }
            
            setTitleColor(titleColorForState(.Normal)!.alpha(loading ? 0 : 1), forState: .Normal)
            
            userInteractionEnabled = !loading
        }
    }
    
    //    private let activeBorderLayer = CALayer()
    
    private let text = UILabel()
    private let loadingView = UIActivityIndicatorView()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.iconOfSize(28)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        text.font = UIFont.displayOfSize(9, withType: .Light)
        text.textColor = .whiteColor()
        text.textAlignment = .Center
        addSubview(text)
        
        //        activeBorderLayer.backgroundColor = UIColor.whiteColor().alpha(0.2).CGColor
        //        layer.addSublayer(activeBorderLayer)
    }
    
    convenience init () {
        self.init(frame: CGRectZero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let textWidth: CGFloat = 50
        text.frame = CGRect(x: (frame.width - textWidth) / 2, y: frame.height + 10, width: textWidth, height: 11)
        
        loadingView.fillSuperview()
        
        //        activeBorderLayer.frame = CGRect(x: -5, y: -5, width: frame.width + 10, height: frame.height + 10)
        //        activeBorderLayer.cornerRadius = activeBorderLayer.frame.width / 2
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let margin: CGFloat = 10
        let area = CGRectInset(bounds, -margin, -margin)
        return CGRectContainsPoint(area, point)
    }
    
}
protocol TabControllerDelegate {
    var tabController: SwipeViewController? { get }
    func jumpToTop()
    func scrollToOptograph(optographID: UUID)
    func onTouchStartCameraButton()
    func onTouchEndCameraButton()
    func onTapCameraButton()
    func onTapLeftButton()
    func onTapRightButton()
    func onTouchOneRingButton()
    func onTouchThreeRingButton()
}

extension TabControllerDelegate {
    func scrollToOptograph(optographID: UUID) {}
    func jumpToTop() {}
    func onTouchStartCameraButton() {}
    func onTouchEndCameraButton() {}
    func onTapCameraButton() {}
    func onTapLeftButton() {}
    func onTapRightButton() {}
    func onTouchOneRingButton() {}
    func onTouchThreeRingButton() {}
}

protocol DefaultTabControllerDelegate: TabControllerDelegate {}



extension DefaultTabControllerDelegate {
    
    func onTapCameraButton() {
        switch PipelineService.stitchingStatus.value {
        case .Idle:
            
            
            let alert:UIAlertController=UIAlertController(title: "Select Mode", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            let cameraAction = UIAlertAction(title: "Optograph", style: UIAlertActionStyle.Default)
            {
                UIAlertAction in
                Defaults[.SessionUploadMode] = "opto"
                //self.tabController!.activeViewController.pushViewController(CameraViewController(), animated: false)
            }
            let gallaryAction = UIAlertAction(title: "Upload Theta", style: UIAlertActionStyle.Default)
            {
                UIAlertAction in
                Defaults[.SessionUploadMode] = "theta"
                self.tabController!.openGallary()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel)
            {
                UIAlertAction in
            }
            alert.addAction(cameraAction)
            alert.addAction(gallaryAction)
            alert.addAction(cancelAction)
            
            tabController?.presentViewController(alert, animated: true, completion: nil)
            
        case .Stitching(_):
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last image has finished rendering.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            tabController?.presentViewController(alert, animated: true, completion: nil)
        case let .StitchingFinished(optographID):
            scrollToOptograph(optographID)
            PipelineService.stitchingStatus.value = .Idle
        case .Uninitialized: ()
        }
    }
    
    func onTapLeftButton() {
//        if tabController?.activeViewController == tabController?.leftViewController {
//            if tabController?.activeViewController.popToRootViewControllerAnimated(true) == nil {
//                jumpToTop()
//            }
//        } else {
//            tabController?.updateActiveTab(.Left)
//        }
        print("nagtap ng left")
    }
    
    func onTapRightButton() {
//        if tabController?.activeViewController == tabController?.rightViewController {
//            if tabController?.activeViewController.popToRootViewControllerAnimated(true) == nil {
//                jumpToTop()
//            }
//        } else {
//            tabController?.updateActiveTab(.Right)
//        }
        print("nagtap ng right")
    }
}

extension UIViewController {
    var tabController: SwipeViewController? {
        return navigationController?.parentViewController as? SwipeViewController
    }
    
    func updateTabs() {
        tabController!.leftButton.title = "HOME"
        tabController!.leftButton.icon = .Home
        tabController!.leftButton.hidden = false
        tabController!.leftButton.color = .Dark
        
        tabController!.rightButton.title = "PROFILE"
        tabController!.rightButton.icon = .User
        tabController!.rightButton.hidden = false
        tabController!.rightButton.color = .Dark
        
        tabController!.cameraButton.icon = UIImage(named:"camera_icn")!
        tabController!.cameraButton.iconColor = .whiteColor()
        tabController!.cameraButton.backgroundColor = .Accent
        
        tabController!.bottomGradientOffset.value = 126
    }
    
    func cleanup() {}
}

extension UINavigationController {
    
    override func cleanup() {
        for vc in viewControllers ?? [] {
            vc.cleanup()
        }
    }
}

extension SwipeViewController: EZSwipeControllerDataSource {
    
    func navigationBarDataForPageIndex(index: Int) -> UINavigationBar {
        
        
        let navigationBar = UINavigationBar()
        
        navigationBar.translucent = true
        navigationBar.barTintColor = UIColor.clearColor()
        navigationBar.setTitleVerticalPositionAdjustment(0, forBarMetrics: .Default)
        navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.displayOfSize(15, withType: .Semibold),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
        ]
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .None)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.enabled = false
        
        if index == 0 {
            let navTitle = UIImage(named:"iam360_navTitle")
            let imageView = UIImageView(image:navTitle)
            navigationItem.titleView = imageView
        
            let cardboardButton = UILabel(frame: CGRect(x: 0, y: -2, width: 24, height: 24))
            cardboardButton.text = String.iconWithName(.Cardboard)
            cardboardButton.textColor = .whiteColor()
            cardboardButton.font = UIFont.iconOfSize(24)
            cardboardButton.userInteractionEnabled = true
            cardboardButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SwipeViewController.showCardboardAlert)))
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cardboardButton)
            navigationBar.pushNavigationItem(navigationItem, animated: false)
        }
        
        return navigationBar
    }
    
    func viewControllerData() -> [UIViewController] {

        let feedsVC = OptographCollectionViewController(viewModel: FeedOptographCollectionViewModel())
        
        let redVC = UIViewController()
        redVC.view.backgroundColor = UIColor.redColor()
        
        let blueVC = UIViewController()
        blueVC.view.backgroundColor = UIColor.blueColor()
        
        let greenVC = UIViewController()
        greenVC.view.backgroundColor = UIColor.greenColor()
        
        return [feedsVC, blueVC, greenVC]
    }
    
    
}

class PassThroughView: UIView {
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.hidden && subview.alpha > 0 && subview.userInteractionEnabled && subview.pointInside(convertPoint(point, toView: subview), withEvent: event) {
                return true
            }
        }
        return false
    }
}

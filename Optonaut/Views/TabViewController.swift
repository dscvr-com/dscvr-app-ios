//
//  TabViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import Async
import Icomoon
import SwiftyUserDefaults
import Result

class TabViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    var scrollView: UIScrollView!
    var tabView = TabView()
    let centerViewController: NavigationController
    let rightViewController: NavigationController
    let leftViewController: NavigationController
    
    var thisView = UIView()
    var isSettingsViewOpen:Bool = false
    private var motorButton = SettingsButton()
    private var manualButton = SettingsButton()
    private var oneRingButton = SettingsButton()
    private var threeRingButton = SettingsButton()
    private var pullButton = SettingsButton()
    
    private let bottomGradient = CAGradientLayer()
    
    let bottomGradientOffset = MutableProperty<CGFloat>(126)
    let isThetaImage = MutableProperty<Bool>(false)
    
    
    var delegate: TabControllerDelegate?
    
    var imageView: UIImageView!
    var imagePicker = UIImagePickerController()
    
    var BFrame:CGRect   = CGRect (
        origin: CGPoint(x: 0, y: 0),
        size: UIScreen.mainScreen().bounds.size
    )
    var adminFrame :CGRect = CGRect (
        origin: CGPoint(x: 0, y: 0),
        size: UIScreen.mainScreen().bounds.size
    )
    
    let labelRing1 = UILabel()
    let labelRing3 = UILabel()
    let labelManual = UILabel()
    let labelMotor = UILabel()
    
    required init() {
        
        centerViewController = FeedNavViewController()
        rightViewController =  ProfileNavViewController()
        leftViewController = SharingNavViewController()
    
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let width = view.frame.width
        
        bottomGradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().alpha(0.5).CGColor]
        tabView.layer.addSublayer(bottomGradient)
        
        bottomGradientOffset.producer.startWithNext { [weak self] offset in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
//            CATransaction.setAnimationDuration(0.3)
//            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            self?.bottomGradient.frame = CGRect(x: 0, y: 0, width: width, height: offset)
            CATransaction.commit()
        }
        
        PipelineService.stitchingStatus.producer
            .observeOnMain()
            .startWithNext { [weak self] status in
                switch status {
                case .Uninitialized:
                    self?.tabView.cameraButton.loading = true
                    print("uninitialized")
                case .Idle:
                    self?.tabView.cameraButton.progress = nil
                    if self?.tabView.cameraButton.progressLocked == false {
                        self?.tabView.cameraButton.icon = UIImage(named:"camera_icn")!
                        self?.tabView.rightButton.loading = false
                    }
                    print("Idle")
                case let .Stitching(progress):
                    self?.tabView.cameraButton.progress = CGFloat(progress)
                    print("Stitching")
                case .StitchingFinished(_):
                    self?.tabView.cameraButton.progress = nil
                    print("StitchingFinished")
                }
        }
        
        initNotificationIndicator()
        
        PipelineService.checkStitching()
        PipelineService.checkUploading()
        
        imagePicker.delegate = self
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.backgroundColor = UIColor.blackColor()
        let scrollWidth: CGFloat  = 3 * self.view.frame.width
        let scrollHeight: CGFloat  = self.view.frame.size.height
        self.scrollView!.contentSize = CGSizeMake(scrollWidth, scrollHeight);
        self.scrollView!.pagingEnabled = true;
        
        self.addChildViewController(centerViewController)
        self.scrollView!.addSubview(centerViewController.view)
        centerViewController.didMoveToParentViewController(self)
        
        self.addChildViewController(leftViewController)
        self.scrollView!.addSubview(leftViewController.view)
        leftViewController.didMoveToParentViewController(self)
        
        self.addChildViewController(rightViewController)
        self.scrollView!.addSubview(rightViewController.view)
        rightViewController.didMoveToParentViewController(self)
        
        adminFrame = leftViewController.view.frame
        adminFrame.origin.x = adminFrame.width
        centerViewController.view.frame = adminFrame
        
        BFrame = centerViewController.view.frame
        BFrame.origin.x = 2*BFrame.width
        rightViewController.view.frame = BFrame
        view.addSubview(scrollView)
        
        tabView.frame = CGRect(x: 0, y: view.frame.height - 126, width: view.frame.width, height: 126)
        centerViewController.view.addSubview(tabView)
        
        scrollView.scrollRectToVisible(adminFrame,animated: false)
        
        isThetaImage.producer
            .filter(isTrue)
            .startWithNext{ _ in
                let alert = UIAlertController(title: "Ooops!", message: "Not a Theta Image, Please choose another photo", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{ _ in
                    self.isThetaImage.value = false
                }))
                self.presentViewController(alert, animated: true, completion: nil)
        }
        
        tabView.cameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TabViewController.tapCameraButton)))
        tabView.cameraButton.addTarget(self, action: #selector(TabViewController.touchStartCameraButton), forControlEvents: [.TouchDown])
        tabView.cameraButton.addTarget(self, action: #selector(TabViewController.touchEndCameraButton), forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
        
        tabView.leftButton.addTarget(self, action: #selector(TabViewController.tapLeftButton), forControlEvents: [.TouchDown])
        tabView.rightButton.addTarget(self, action: #selector(TabViewController.tapRightButton), forControlEvents: [.TouchDown])
        
        imagePicker.delegate = self
        
        self.settingsView()
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TabViewController.handlePan(_:)))
        self.centerViewController.navigationBar.addGestureRecognizer(panGestureRecognizer)
        
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
    func rightButtonAction() {
        UIView.animateWithDuration(0.5, animations: {
            self.scrollView.scrollRectToVisible(self.BFrame,animated: false)
            }, completion:nil)
    }
    
    func disableScrollView() {
        scrollView.scrollEnabled = false;
    }
    
    func enableScrollView() {
        scrollView.scrollEnabled = true;
    }
    
    func swipeLeftView(xPoint:CGFloat) {
        
        print("pumasok dito")
        self.scrollView.scrollRectToVisible(CGRect(x: self.view.frame.width - xPoint,y: 0,width:xPoint,height: self.view.frame.height),animated: false)
    }
    
    func swipeRightView() {
        scrollView.scrollRectToVisible(BFrame,animated: false)
    }
    
    func settingsView() {
        thisView.frame = CGRectMake(0, -(view.frame.height), view.frame.width, view.frame.height)
        thisView.backgroundColor = UIColor.blackColor()
        self.view.addSubview(thisView)
        
        let image: UIImage = UIImage(named: "logo_big")!
        var bgImage: UIImageView?
        bgImage = UIImageView(image: image)
        thisView.addSubview(bgImage!)
        bgImage!.anchorToEdge(.Top, padding: 60, width: view.frame.size.width * 0.5, height: view.frame.size.height * 0.13)
        
        let labelHeightMultiplier:CGFloat = 0.3 * bgImage!.frame.size.height
        let buttonsHeightMultiplier:CGFloat = 0.9 * bgImage!.frame.size.height
        
        let labelCamera = UILabel()
        labelCamera.textAlignment = NSTextAlignment.Center
        labelCamera.text = "Camera Settings"
        labelCamera.textColor = UIColor.whiteColor()
        thisView.addSubview(labelCamera)
        labelCamera.align(.UnderCentered, relativeTo: bgImage!, padding: 15, width: 200, height: labelHeightMultiplier)
        
        let labelMode = UILabel()
        labelMode.textAlignment = NSTextAlignment.Center
        labelMode.textColor = UIColor.whiteColor()
        labelMode.text = "Mode"
        thisView.addSubview(labelMode)
        labelMode.align(.UnderCentered, relativeTo: labelCamera, padding: 15, width: 100, height: labelHeightMultiplier)
        
        oneRingButton.frame = CGRect(x: self.view.frame.width*0.25 , y: labelMode.frame.origin.y + 40 , width: buttonsHeightMultiplier, height: buttonsHeightMultiplier)
        oneRingButton.addTarget(self, action: #selector(TabViewController.oneRingButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(oneRingButton)
        
        labelRing1.textAlignment = NSTextAlignment.Center
        labelRing1.text = "One Ring"
        labelRing1.align(.UnderCentered, relativeTo: oneRingButton, padding: 5, width: 200, height: labelHeightMultiplier)
        thisView.addSubview(labelRing1)
        
        threeRingButton.align(.ToTheRightMatchingTop, relativeTo: oneRingButton, padding: 40, width: buttonsHeightMultiplier, height: buttonsHeightMultiplier)
        threeRingButton.addTarget(self, action: #selector(TabViewController.threeRingButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(threeRingButton)
        
        labelRing3.textAlignment = NSTextAlignment.Center
        labelRing3.text = "Three Ring"
        labelRing3.align(.UnderCentered, relativeTo: threeRingButton, padding: 5, width: 200, height: labelHeightMultiplier)
        thisView.addSubview(labelRing3)
        
        let line = UILabel()
        line.frame = CGRect(x: 15 , y: labelRing3.frame.origin.y + labelRing3.frame.height + 50 , width: self.view.frame.width-15, height: 1)
        line.backgroundColor = UIColor.grayColor()
        thisView.addSubview(line)
        
        let labelCapture = UILabel()
        labelCapture.textAlignment = NSTextAlignment.Center
        labelCapture.text = "Capture Type"
        labelCapture.textColor = UIColor.whiteColor()
        thisView.addSubview(labelCapture)
        labelCapture.align(.UnderCentered, relativeTo: line, padding: 15, width: 200, height: labelHeightMultiplier)
        
        manualButton.frame = CGRect(x: self.view.frame.width*0.25 , y: labelCapture.frame.origin.y + 40 , width: buttonsHeightMultiplier, height: buttonsHeightMultiplier)
        manualButton.addTarget(self, action: #selector(TabViewController.manualButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(manualButton)
        
        motorButton.align(.ToTheRightMatchingTop, relativeTo: manualButton, padding: 40, width: buttonsHeightMultiplier, height: buttonsHeightMultiplier)
        motorButton.addTarget(self, action: #selector(TabViewController.motorButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(motorButton)
        
        labelManual.textAlignment = NSTextAlignment.Center
        labelManual.text = "Manual"
        labelManual.textColor = UIColor(hex:0xffbc00)
        labelManual.align(.UnderCentered, relativeTo: manualButton, padding: 5, width: 200, height:labelHeightMultiplier)
        thisView.addSubview(labelManual)
        
        labelMotor.textAlignment = NSTextAlignment.Center
        labelMotor.text = "Motor"
        labelMotor.textColor = UIColor(hex:0xffbc00)
        labelMotor.align(.UnderCentered, relativeTo: motorButton, padding: 5, width: 200, height:labelHeightMultiplier)
        thisView.addSubview(labelMotor)
        
        pullButton.icon = UIImage(named:"arrow_pull")!
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TabViewController.handlePan(_:)))
        pullButton.addGestureRecognizer(panGestureRecognizer)
        thisView.addGestureRecognizer(panGestureRecognizer)
        
        //pullButton.addTarget(self, action: #selector(FeedNavViewController.pullButtonTap), forControlEvents:.TouchUpInside)
        thisView.addSubview(pullButton)
        pullButton.anchorToEdge(.Bottom, padding: 5, width: 20, height: 15)
        
        self.activeRingButtons(Defaults[.SessionUseMultiRing])
        self.activeModeButtons(Defaults[.SessionMotor])
    }
    
    
    func pullButtonTap() {
        UIView.animateWithDuration(1.0, delay: 1.2, options: .CurveEaseOut, animations: {
            if var settingsViewCount:CGFloat = self.thisView.frame.origin.y {
                settingsViewCount -= self.view.frame.origin.y
                self.thisView.frame = CGRectMake(0, settingsViewCount , self.view.frame.width, self.view.frame.height)
            }
            }, completion: { finished in
                self.isSettingsViewOpen = false
                
        })
    }
    
    
    
    func motorButtonTouched() {
        Defaults[.SessionMotor] = true
        self.activeModeButtons(true)
    }
    
    func manualButtonTouched() {
        Defaults[.SessionMotor] = false
        self.activeModeButtons(false)
    }
    
    func oneRingButtonTouched() {
        Defaults[.SessionUseMultiRing] = false
        self.activeRingButtons(false)
    }
    
    func threeRingButtonTouched() {
        Defaults[.SessionUseMultiRing] = true
        self.activeRingButtons(true)
    }
    func activeModeButtons(isMotor:Bool) {
        if isMotor {
            motorButton.icon = UIImage(named: "motor_active_icn")!
            manualButton.icon = UIImage(named: "manual_inactive_icn")!
            
            labelManual.textColor = UIColor.grayColor()
            labelMotor.textColor = UIColor(hex:0xffbc00)
        } else {
            motorButton.icon = UIImage(named: "motor_inactive_icn")!
            manualButton.icon = UIImage(named: "manual_active_icn")!
            
            labelManual.textColor = UIColor(hex:0xffbc00)
            labelMotor.textColor = UIColor.grayColor()
        }
    }
    
    func activeRingButtons(isMultiRing:Bool) {
        
        if isMultiRing {
            threeRingButton.icon = UIImage(named: "threeRing_active_icn")!
            oneRingButton.icon = UIImage(named: "oneRing_inactive_icn")!
            
            labelRing3.textColor = UIColor(hex:0xffbc00)
            labelRing1.textColor = UIColor.grayColor()
            
        } else {
            threeRingButton.icon = UIImage(named: "threeRing_inactive_icn")!
            oneRingButton.icon = UIImage(named: "oneRing_active_icn")!
            
            labelRing3.textColor = UIColor.grayColor()
            labelRing1.textColor = UIColor(hex:0xffbc00)
        }
    }
    
    func handlePan(recognizer:UIPanGestureRecognizer) {
        
        let translationY = recognizer.translationInView(self.view).y
        
        switch recognizer.state {
        case .Began:
            print("wew")
        case .Changed:
            
            if !isSettingsViewOpen {
                thisView.frame = CGRectMake(0, translationY - self.view.frame.height , self.view.frame.width, self.view.frame.height)
            } else {
                thisView.frame = CGRectMake(0,self.view.frame.height - (self.view.frame.height - translationY) , self.view.frame.width, self.view.frame.height)
            }
        case .Cancelled:
            print("cancelled")
        case .Ended:
            if !isSettingsViewOpen{
                thisView.frame = CGRectMake(0, 0 , self.view.frame.width, self.view.frame.height)
                isSettingsViewOpen = true
            } else {
                thisView.frame = CGRectMake(0, -(self.view.frame.height) , self.view.frame.width, self.view.frame.height)
                isSettingsViewOpen = false
            }
            
        default: break
        }
    }
    
    func openGallary() {
        
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.navigationBar.translucent = false
        imagePicker.navigationBar.barTintColor = UIColor(hex:0x343434)
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
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showUI() {
        tabView.hidden = false
    }
    
    func hideUI() {
        tabView.hidden = true
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
    private func initNotificationIndicator() {
        let circle = UILabel()
        circle.frame = CGRect(x: tabView.rightButton.frame.origin.x + 25, y: tabView.rightButton.frame.origin.y - 3, width: 16, height: 16)
        circle.backgroundColor = .Accent
        circle.font = UIFont.displayOfSize(10, withType: .Regular)
        circle.textAlignment = .Center
        circle.textColor = .whiteColor()
        circle.layer.cornerRadius = 8
        circle.clipsToBounds = true
        circle.hidden = true
        tabView.addSubview(circle)
        
        ActivitiesService.unreadCount.producer.startWithNext { count in
            let hidden = count <= 0
            circle.hidden = hidden
            circle.text = "\(count)"
        }
    }

}

class TButton: UIButton {
    
    enum Color { case Light, Dark }
    
    var title: String = "" {
        didSet {
            text.text = title
        }
    }
    
    var icon: UIImage = UIImage(named:"photo_library_icn")! {
        didSet {
            setImage(icon, forState: .Normal)
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
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let margin: CGFloat = 10
        let area = CGRectInset(bounds, -margin, -margin)
        return CGRectContainsPoint(area, point)
    }
    
}
private class SettingsButton : UIButton {
    
    var icon: UIImage = UIImage(named:"motor_active_icn")!{
        didSet{
            setImage(icon, forState: .Normal)
        }
    }
}

class RecButton: UIButton {
    
    private var touched = false
    
    private let progressLayer = CALayer()
    private let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    
    var icon: UIImage = UIImage(named:"camera_icn")! {
        didSet {
            setImage(icon, forState: .Normal)
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
                    backgroundColor = UIColor.clearColor()
                    loading = progress != 1
                } else {
                    backgroundColor = UIColor.clearColor()
                    loading = false
                }
                
                layoutSubviews()
            }
        }
    }
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        //progressLayer.backgroundColor = UIColor.clearColor()
        layer.addSublayer(progressLayer)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        backgroundColor = UIColor.clearColor()
        clipsToBounds = true
        
        layer.cornerRadius = 12
        
        setTitleColor(.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.iconOfSize(33)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        progressLayer.frame = CGRect(x: 0, y: 0, width: frame.width * (progress ?? 0), height: frame.height)
        loadingView.fillSuperview()
    }
}

protocol TabControllerDelegate {
    var tabController: TabViewController? { get }
    func jumpToTop()
    func scrollToOptograph(optographID: UUID)
    func onTouchStartCameraButton()
    func onTouchEndCameraButton()
    func onTapCameraButton()
    func onTapLeftButton()
    func onTapRightButton()
}

extension TabControllerDelegate {
    func scrollToOptograph(optographID: UUID) {}
    func jumpToTop() {}
    func onTouchStartCameraButton() {}
    func onTouchEndCameraButton() {}
    func onTapCameraButton() {}
    func onTapLeftButton() {}
    func onTapRightButton() {}
    func onTapRightTabBarItem(){}
}

protocol DefaultTabControllerDelegate: TabControllerDelegate {}

extension DefaultTabControllerDelegate {
    
    func onTapCameraButton() {
        switch PipelineService.stitchingStatus.value {
        case .Idle:
            self.tabController!.centerViewController.cleanup()
            
            self.tabController!.centerViewController.pushViewController(CameraViewController(), animated: false)
            
        case .Stitching(_):
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last image has finished rendering.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            //tabController?.activeViewController.presentViewController(alert, animated: true, completion: nil)
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
        tabController!.openGallary()
        print("onTapLeftButton")
    }
    
    func onTapRightButton() {
//        if tabController?.activeViewController == tabController?.rightViewController {
//            if tabController?.activeViewController.popToRootViewControllerAnimated(true) == nil {
//                jumpToTop()
//            }
//        } else {
//            tabController?.updateActiveTab(.Right)
//        }
        
        print("onTapRightButton")
    }
}

extension UIViewController {
    var tabController: TabViewController? {
        return navigationController?.parentViewController as? TabViewController
    }
    
    func updateTabs() {
        tabController!.tabView.leftButton.icon = UIImage(named:"photo_library_icn")!
        
        tabController!.tabView.rightButton.icon = UIImage(named:"settings_icn")!
        
        tabController!.tabView.cameraButton.icon = UIImage(named:"camera_icn")!
        
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
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

class TabViewController: UIViewController {
    
    enum ActiveSide: Equatable { case Left, Right }
    
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    
    private let borderLineLayer = CALayer()
    
    private let uiWrapper = PassThroughView()
    
    let cameraButton = RecordButton()
    let leftButton = TabButton()
    let rightButton = TabButton()
    
    private let bottomGradient = CAGradientLayer()
    
    private let bottomGradientOffset = MutableProperty<CGFloat>(0)
    
    let leftViewController: CollectionNavViewController
    let rightViewController: ProfileNavViewController
    var activeViewController: NavigationController
    
    private var uiHidden = false
    
    var delegate: TabControllerDelegate?
    
    required init() {
        leftViewController = CollectionNavViewController()
        rightViewController = ProfileNavViewController()
        
        activeViewController = leftViewController
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChildViewController(leftViewController)
        addChildViewController(rightViewController)
        
        view.insertSubview(leftViewController.view, atIndex: 0)
        
        let width = view.frame.width
        
        bottomGradient.frame = CGRect(x: 0, y: 0, width: width, height: 126)
        bottomGradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().alpha(0.5).CGColor]
        uiWrapper.layer.addSublayer(bottomGradient)
        
        bottomGradientOffset.producer.startWithNext { [weak self] offset in
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            self?.bottomGradient.frame = CGRect(x: 0, y: 0, width: width, height: offset + 126)
            CATransaction.commit()
        }
        
//        blurView.frame = CGRect(x: 0, y: 1, width: view.frame.width, height: 107)
//        blurView.alpha = 0.95
//        uiWrapper.addSubview(blurView)
        
//        borderLineLayer.backgroundColor = UIColor.whiteColor().CGColor
//        borderLineLayer.opacity = 0.5
//        borderLineLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 1)
//        uiWrapper.layer.addSublayer(borderLineLayer)
        
        cameraButton.frame = CGRect(x: view.frame.width / 2 - 35, y: 126 / 2 - 35, width: 70, height: 70)
        cameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapCameraButton"))
        cameraButton.addTarget(self, action: "touchStartCameraButton", forControlEvents: [.TouchDown])
        cameraButton.addTarget(self, action: "touchEndCameraButton", forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
        uiWrapper.addSubview(cameraButton)
        
//        #if DEBUG
//            let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "_debug_showCameraAlert")
//            longPressGestureRecognizer.minimumPressDuration = 1
//            cameraButton.addGestureRecognizer(longPressGestureRecognizer)
//        #endif
        
        PipelineService.status.producer
            .observeOnMain()
            .startWithNext { [weak self] status in
                switch status {
                case .Idle: self?.cameraButton.progress = 0
                case let .Stitching(progress): self?.cameraButton.progress = CGFloat(progress)
                default: ()
                }
            }

        leftButton.isActive = true
        leftButton.frame = CGRect(x: view.frame.width * 1.01 / 4 - 34, y: 126 / 2 - 23.5, width: 34, height: 34)
        leftButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapLeftButton"))
        uiWrapper.addSubview(leftButton)

        rightButton.isActive = false
        rightButton.frame = CGRect(x: view.frame.width * 2.99 / 4, y: 126 / 2 - 23.5, width: 34, height: 34)
        rightButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapRightButton"))
        uiWrapper.addSubview(rightButton)
        
        initNotificationIndicator()
        
        uiWrapper.frame = CGRect(x: 0, y: view.frame.height - 126, width: view.frame.width, height: 126)
        view.addSubview(uiWrapper)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Async.background {
            PipelineService.check()
        }
    }
    
    func showUI() {
        uiWrapper.hidden = false
    }
    
    func hideUI() {
        uiWrapper.hidden = true
    }
    
    @objc
    private func tapLeftButton() {
        delegate?.onTapLeftButton()
    }
    
    @objc
    private func tapRightButton() {
        delegate?.onTapRightButton()
    }
    
    @objc
    private func tapCameraButton() {
        delegate?.onTapCameraButton()
    }
    
    @objc
    private func touchStartCameraButton() {
        delegate?.onTouchStartCameraButton()
    }
    
    @objc
    private func touchEndCameraButton() {
        delegate?.onTouchEndCameraButton()
    }
    
    private func updateActiveTab(side: ActiveSide) {
        let isLeft = side == .Left
        leftButton.isActive = isLeft
        rightButton.isActive = !isLeft
        
        activeViewController.view.removeFromSuperview()
        activeViewController = isLeft ? leftViewController : rightViewController
        view.insertSubview(activeViewController.view, atIndex: 0)
    }
    
    private func initNotificationIndicator() {
        let circle = UILabel()
        circle.frame = CGRect(x: rightButton.frame.origin.x + 25, y: rightButton.frame.origin.y - 3, width: 16, height: 16)
        circle.backgroundColor = .Accent
        circle.font = UIFont.displayOfSize(10, withType: .Regular)
        circle.textAlignment = .Center
        circle.textColor = .whiteColor()
        circle.layer.cornerRadius = 8
        circle.clipsToBounds = true
        circle.hidden = true
        uiWrapper.addSubview(circle)
        
        ActivitiesService.unreadCount.producer.startWithNext { count in
            let hidden = count <= 0
            circle.hidden = hidden
            circle.text = "\(count)"
        }
    }
    
    @objc
    private func _debug_showCameraAlert() {
        let confirmAlert = UIAlertController(title: "Choose wisely", message: "", preferredStyle: .Alert)
        confirmAlert.addAction(UIAlertAction(title: "Skip to save screen", style: .Default, handler: { _ in
            
        }))
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        self.presentViewController(confirmAlert, animated: true, completion: nil)
    }

}

class RecordButton: UIButton {
    
    private var touched = false
    
    private let progressLayer = CALayer()
    
    var progress: CGFloat = 0 {
        didSet {
            if progress == 0 {
                setTitle(String.iconWithName(.Camera_Alt), forState: .Normal)
            } else if progress == 1 {
                setTitle(String.iconWithName(.Check), forState: .Normal)
            } else {
                setTitle(String.iconWithName(.Feed), forState: .Normal)
            }
            layoutSubviews()
        }
    }
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        progressLayer.backgroundColor = UIColor.Accent.mixWithColor(.blackColor(), amount: 0.1).CGColor
        
        layer.addSublayer(progressLayer)
        
        backgroundColor = .Accent
        clipsToBounds = true
        
        layer.cornerRadius = 12
        
        setTitleColor(.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.iconOfSize(33)
        
        addTarget(self, action: "buttonTouched", forControlEvents: .TouchDown)
        addTarget(self, action: "buttonUntouched", forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        progressLayer.frame = CGRect(x: 0, y: 0, width: frame.width * progress, height: frame.height)
    }
    
    private func updateBackground() {
        if touched {
            backgroundColor = UIColor.Accent.alpha(0.7)
        } else {
            backgroundColor = .Accent
        }
    }
    
    @objc
    private func buttonTouched() {
        touched = true
        updateBackground()
    }
    
    @objc
    private func buttonUntouched() {
        touched = false
        updateBackground()
    }
}

class TabButton: UIButton {
    
    var title: String = "" {
        didSet {
            text.text = title
        }
    }
    
    var icon: Icon = .Explore {
        didSet {
            setTitle(String.iconWithName(icon), forState: .Normal)
        }
    }
    
    var isActive: Bool = false {
        didSet {
            alpha = isActive ? 1 : 0.5
            activeBorderLayer.hidden = !isActive
        }
    }
    
    private let activeBorderLayer = CALayer()
    
    private let text = UILabel()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(.whiteColor(), forState: .Normal)
        titleLabel?.font = UIFont.iconOfSize(34)
        
        text.font = UIFont.displayOfSize(9, withType: .Light)
        text.textColor = .whiteColor()
        text.textAlignment = .Center
        addSubview(text)
        
        activeBorderLayer.backgroundColor = UIColor.whiteColor().alpha(0.2).CGColor
        layer.addSublayer(activeBorderLayer)
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
        
        activeBorderLayer.frame = CGRect(x: -5, y: -5, width: frame.width + 10, height: frame.height + 10)
        activeBorderLayer.cornerRadius = activeBorderLayer.frame.width / 2
    }
    
}

protocol TabControllerDelegate {
    var tabController: TabViewController? { get }
    func jumpToTop()
    func scrollToOptograph(optograph: Optograph)
    func onTouchStartCameraButton()
    func onTouchEndCameraButton()
    func onTapCameraButton()
    func onTapLeftButton()
    func onTapRightButton()
}

extension TabControllerDelegate {
    func scrollToOptograph(optograph: Optograph) {}
    func jumpToTop() {}
    func onTouchStartCameraButton() {}
    func onTouchEndCameraButton() {}
    func onTapCameraButton() {}
    func onTapLeftButton() {}
    func onTapRightButton() {}
}

protocol DefaultTabControllerDelegate: TabControllerDelegate {}

extension DefaultTabControllerDelegate {
    
    func onTapCameraButton() {
        switch PipelineService.status.value {
        case .Idle:
            tabController?.activeViewController.pushViewController(CameraViewController(), animated: false)
        case .Stitching(_):
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last image has finished rendering.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            tabController?.activeViewController.presentViewController(alert, animated: true, completion: nil)
        case let .StitchingFinished(optograph):
            scrollToOptograph(optograph)
            PipelineService.status.value = .Idle
        }
    }
    
    func onTapLeftButton() {
        if tabController?.activeViewController == tabController?.leftViewController {
            if tabController?.activeViewController.popToRootViewControllerAnimated(true) == nil {
                jumpToTop()
            }
        } else {
            tabController?.updateActiveTab(.Left)
        }
    }
    
    func onTapRightButton() {
        if tabController?.activeViewController == tabController?.rightViewController {
            if tabController?.activeViewController.popToRootViewControllerAnimated(true) == nil {
                jumpToTop()
            }
        } else {
            tabController?.updateActiveTab(.Right)
        }
    }
    
}

extension UIViewController {
    var tabController: TabViewController? {
        return navigationController?.parentViewController as? TabViewController
    }
    
    func updateTabs() {
        tabController!.leftButton.title = "HOME"
        tabController!.leftButton.icon = .Explore
        tabController!.leftButton.hidden = false
        
        tabController!.rightButton.title = "PROFILE"
        tabController!.rightButton.icon = .Account_Circle
        tabController!.rightButton.hidden = false
        
        tabController!.cameraButton.setTitle(String.iconWithName(.Camera_Alt), forState: .Normal)
        tabController!.cameraButton.setTitleColor(.whiteColor(), forState: .Normal)
        tabController!.cameraButton.backgroundColor = .Accent
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
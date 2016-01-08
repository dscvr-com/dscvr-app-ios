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

class TabViewController: UIViewController {
    
    enum ActiveSide: Equatable { case Left, Right }
    
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    
    private let borderLineLayer = CALayer()
    
    private let uiWrapper = PassThroughView()
    private let recordButton = RecordButton()
    private let leftButton = TabButton()
    private let rightButton = TabButton()
    private let bottomGradient = CAGradientLayer()
    
    private let bottomGradientOffset = MutableProperty<CGFloat>(0)
    
    private let leftViewController: CollectionNavViewController
    private let rightViewController: ProfileNavViewController
    private var activeViewController: NavigationController
    
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
        
        recordButton.frame = CGRect(x: view.frame.width / 2 - 35, y: 126 / 2 - 35, width: 70, height: 70)
        recordButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushCamera"))
        uiWrapper.addSubview(recordButton)
        
        #if DEBUG
            let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "_debug_showCameraAlert")
            longPressGestureRecognizer.minimumPressDuration = 1
            recordButton.addGestureRecognizer(longPressGestureRecognizer)
        #endif
        
        PipelineService.status.producer.startWithNext { [weak self] status in
            switch status {
            case .Idle: self?.recordButton.progress = 0
            case let .Stitching(progress): self?.recordButton.progress = CGFloat(progress)
            default: ()
            }
        }

        leftButton.isActive = true
        leftButton.type = .Home
        leftButton.frame = CGRect(x: view.frame.width * 1.01 / 4 - 34, y: 126 / 2 - 23.5, width: 34, height: 34)
        leftButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapLeftButton"))
        uiWrapper.addSubview(leftButton)

        rightButton.isActive = false
        rightButton.type = .Profile
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
    
    func tapLeftButton() {
        if activeViewController == leftViewController {
            if activeViewController.popToRootViewControllerAnimated(true) == nil {
                delegate?.jumpToTop()
            }
        } else {
            updateActiveTab(.Left)
        }
    }
    
    func tapRightButton() {
        if activeViewController == rightViewController {
            if activeViewController.popToRootViewControllerAnimated(true) == nil {
                delegate?.jumpToTop()
            }
        } else {
            updateActiveTab(.Right)
        }
    }
    
    func pushCamera() {
        switch PipelineService.status.value {
        case .Idle:
            activeViewController.pushViewController(CameraViewController(), animated: false)
        case .Stitching(_):
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last image has finished rendering.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            activeViewController.presentViewController(alert, animated: true, completion: nil)
        case let .StitchingFinished(optograph):
            delegate?.scrollToOptograph(optograph)
            PipelineService.status.value = .Idle
        }
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

private class RecordButton: UIButton {
    
    private let progressLayer = CALayer()
    
    private var touched = false
    
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
    
    convenience init () {
        self.init(frame: CGRectZero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func layoutSubviews() {
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

private class TabButton: UIButton {
    
    enum Type { case Home, Profile }
    var type: Type = .Home {
        didSet {
            switch type {
            case .Home:
                text.text = "HOME"
                setTitle(String.iconWithName(.Explore), forState: .Normal)
            case .Profile:
                text.text = "PROFILE"
                setTitle(String.iconWithName(.Account_Circle), forState: .Normal)
            }
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
    
    private override func layoutSubviews() {
        super.layoutSubviews()
        
        let textWidth: CGFloat = 50
        text.frame = CGRect(x: (frame.width - textWidth) / 2, y: frame.height + 10, width: textWidth, height: 11)
        
        activeBorderLayer.frame = CGRect(x: -5, y: -5, width: frame.width + 10, height: frame.height + 10)
        activeBorderLayer.cornerRadius = activeBorderLayer.frame.width / 2
    }
    
}

protocol TabControllerDelegate {
    func jumpToTop()
    func scrollToOptograph(optograph: Optograph)
}

extension TabControllerDelegate {
    func scrollToOptograph(optograph: Optograph) {}
}

extension UIViewController {
    var tabController: TabViewController? {
        return navigationController?.parentViewController as? TabViewController
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
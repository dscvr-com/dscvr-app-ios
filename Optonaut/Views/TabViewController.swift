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
    
    private let uiWrapper = PassThroughView()
    
    var indicatedSide: ActiveSide? {
        didSet {
            updateIndicatedSide()
        }
    }
    
    private let indicatedSideLayer = CALayer()
    
    let cameraButton = RecordButton()
    let leftButton = TabButton()
    let rightButton = TabButton()
    
    private let bottomGradient = CAGradientLayer()
    
    let bottomGradientOffset = MutableProperty<CGFloat>(126)
    
    let leftViewController: NavigationController
    let rightViewController: NavigationController
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
        
//        view.insertSubview(leftViewController.view, atIndex: 0)
        view.insertSubview(rightViewController.view, atIndex: 0)
        
        let width = view.frame.width
        
        bottomGradient.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().alpha(0.5).CGColor]
        uiWrapper.layer.addSublayer(bottomGradient)
        
        indicatedSideLayer.backgroundColor = UIColor.Accent.CGColor
        indicatedSideLayer.cornerRadius = 5
        uiWrapper.layer.addSublayer(indicatedSideLayer)
        
        bottomGradientOffset.producer.startWithNext { [weak self] offset in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
//            CATransaction.setAnimationDuration(0.3)
//            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            self?.bottomGradient.frame = CGRect(x: 0, y: 0, width: width, height: offset)
            CATransaction.commit()
        }
        
        cameraButton.frame = CGRect(x: view.frame.width / 2 - 35, y: 126 / 2 - 35, width: 70, height: 70)
        cameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapCameraButton"))
        cameraButton.addTarget(self, action: "touchStartCameraButton", forControlEvents: [.TouchDown])
        cameraButton.addTarget(self, action: "touchEndCameraButton", forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel])
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
                        self?.cameraButton.icon = .Camera
                    }
                case let .Stitching(progress):
                    self?.cameraButton.progress = CGFloat(progress)
                case .StitchingFinished(_):
                    self?.cameraButton.progress = 1
                }
            }

        let buttonSpacing = (view.frame.width / 2 - 35) / 2 - 14
        leftButton.frame = CGRect(x: buttonSpacing, y: 126 / 2 - 23.5, width: 28, height: 28)
        leftButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapLeftButton"))
        uiWrapper.addSubview(leftButton)

        rightButton.frame = CGRect(x: view.frame.width - buttonSpacing - 28, y: 126 / 2 - 23.5, width: 28, height: 28)
        rightButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapRightButton"))
        uiWrapper.addSubview(rightButton)
        
        initNotificationIndicator()
        
        uiWrapper.frame = CGRect(x: 0, y: view.frame.height - 126, width: view.frame.width, height: 126)
        view.addSubview(uiWrapper)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        PipelineService.checkStitching()
        PipelineService.checkUploading()
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
        
        activeViewController.view.removeFromSuperview()
        activeViewController = isLeft ? leftViewController : rightViewController
        view.insertSubview(activeViewController.view, atIndex: 0)
    }
    
    private func updateIndicatedSide() {
        indicatedSideLayer.hidden = indicatedSide == nil
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let spacing = (view.frame.width / 2 - 35) / 2 - 31
        switch indicatedSide {
        case .Left?: indicatedSideLayer.frame = CGRect(x: spacing, y: 121, width: 62, height: 10)
        case .Right?: indicatedSideLayer.frame = CGRect(x: view.frame.width - spacing - 62, y: 121, width: 62, height: 10)
        default: ()
        }
        
        CATransaction.commit()
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

}

class RecordButton: UIButton {
    
    private var touched = false
    
    private let progressLayer = CALayer()
    private let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    
    var icon: Icon = .Camera {
        didSet {
            setTitle(String.iconWithName(icon), forState: .Normal)
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
                    
                    if progress == 0 {
                        icon = .Camera
                    } else if progress == 1 {
                        icon = .Next
                    }
                } else {
                    backgroundColor = UIColor.Accent
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
        
        progressLayer.frame = CGRect(x: 0, y: 0, width: frame.width * (progress ?? 0), height: frame.height)
        loadingView.fillSuperview()
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
    var tabController: TabViewController? { get }
    func jumpToTop()
    func scrollToOptograph(optographID: UUID)
    func onTouchStartCameraButton()
    func onTouchEndCameraButton()
    func onTapCameraButton()
    func onTapLeftButton()
    func onTapRightButton()
    func cleanup()
}

extension TabControllerDelegate {
    func scrollToOptograph(optographID: UUID) {}
    func jumpToTop() {}
    func onTouchStartCameraButton() {}
    func onTouchEndCameraButton() {}
    func onTapCameraButton() {}
    func onTapLeftButton() {}
    func onTapRightButton() {}
    func cleanup() {}
}

protocol DefaultTabControllerDelegate: TabControllerDelegate {}

extension DefaultTabControllerDelegate {
    
    func onTapCameraButton() {
        switch PipelineService.stitchingStatus.value {
        case .Idle:
            cleanup()
            tabController?.activeViewController.pushViewController(CameraViewController(), animated: false)
        case .Stitching(_):
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last image has finished rendering.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { _ in return }))
            tabController?.activeViewController.presentViewController(alert, animated: true, completion: nil)
        case let .StitchingFinished(optographID):
            scrollToOptograph(optographID)
            PipelineService.stitchingStatus.value = .Idle
        case .Uninitialized: ()
        }
    }
    
    func onTapLeftButton() {
        if tabController?.activeViewController == tabController?.leftViewController {
            if tabController?.activeViewController.popToRootViewControllerAnimated(true) == nil {
                jumpToTop()
            }
        } else {
            tabController?.updateActiveTab(.Left)
            tabController?.indicatedSide = .Left
        }
    }
    
    func onTapRightButton() {
        if tabController?.activeViewController == tabController?.rightViewController {
            if tabController?.activeViewController.popToRootViewControllerAnimated(true) == nil {
                jumpToTop()
            }
        } else {
            tabController?.updateActiveTab(.Right)
            tabController?.indicatedSide = .Right
        }
    }
    
}

extension UIViewController {
    var tabController: TabViewController? {
        return navigationController?.parentViewController as? TabViewController
    }
    
    func updateTabs() {
        tabController!.indicatedSide = .Left
        
        tabController!.leftButton.title = "HOME"
        tabController!.leftButton.icon = .Home
        tabController!.leftButton.hidden = false
        tabController!.leftButton.color = .Dark
        
        tabController!.rightButton.title = "PROFILE"
        tabController!.rightButton.icon = .User
        tabController!.rightButton.hidden = false
        tabController!.rightButton.color = .Dark
        
        tabController!.cameraButton.icon = .Camera
        tabController!.cameraButton.iconColor = .whiteColor()
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

//
//  TabViewController.swift
//  Optonaut
//
//  Created by Robert John M Alkuino on 03/12/2016.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveSwift
import Async
//import Icomoon
import SwiftyUserDefaults
import Result

class TabViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    enum ActiveSide: Equatable { case left, right }
    
    fileprivate let uiWrapper = PassThroughView()
    
    let cameraButton = RecordButton()
    
    fileprivate let bottomGradient = CAGradientLayer()
    
    let bottomGradientOffset = MutableProperty<CGFloat>(126)
    let leftViewController: NavigationController
    
    fileprivate var uiHidden = false
    fileprivate var uiLocked = false
    
    var delegate: TabControllerDelegate?
    
    //var progress = KDCircularProgress()
    
    required init() {
        leftViewController = FeedNavViewController()
        
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChildViewController(leftViewController)
        
        view.insertSubview(leftViewController.view, at: 0)
        
        let width = view.frame.width
        
        bottomGradient.colors = [UIColor.clear.cgColor, UIColor.black.alpha(0.5).cgColor]
        uiWrapper.layer.addSublayer(bottomGradient)
        
        bottomGradientOffset.producer.startWithValues { [weak self] offset in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self?.bottomGradient.frame = CGRect(x: 0, y: 0, width: width, height: offset)
            CATransaction.commit()
        }
        
        cameraButton.frame = CGRect(x: view.frame.width / 2 - 35, y: 126 / 2 - 35, width: 70, height: 70)
        cameraButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TabViewController.tapCameraButton)))
        cameraButton.addTarget(self, action: #selector(TabViewController.touchStartCameraButton), for: [.touchDown])
        cameraButton.addTarget(self, action: #selector(TabViewController.touchEndCameraButton), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        uiWrapper.addSubview(cameraButton)
        
//        createStitchingProgressBar()
        
        PipelineService.stitchingStatus.producer
            .observeOnMain()
            .startWithValues { [weak self] status in
                switch status {
                case .uninitialized:
                    self?.cameraButton.loading = true
                case .idle:
                    self?.cameraButton.progress = nil
                    if self?.cameraButton.progressLocked == false {
                        self?.cameraButton.icon = UIImage(named:"camera_icn")!
                    }
                case let .stitching(progress):
//                    if self?.progress.hidden == true {
//                        self?.progress.hidden = false
//                    }
//                    let progressSize:Double = Double(progress * 360)
//                    self?.progress.angle = progressSize
                    
                    self?.cameraButton.progress = CGFloat(progress)
                case .stitchingFinished(_):
//                    self?.progress.angle = 360
//                    self?.progress.hidden = true
                    self?.cameraButton.progress = nil
                }
        }
        
        PipelineService.checkStitching()
        
        uiWrapper.frame = CGRect(x: 0, y: view.frame.height - 126, width: view.frame.width, height: 126)
        view.addSubview(uiWrapper)
    }
    
//    func createStitchingProgressBar() {
//        let sizeWidth = UIImage(named:"camera_icn")!.size.width
//        let sizeHeight = UIImage(named:"camera_icn")!.size.height
//        
//        progress = KDCircularProgress(frame: CGRect(x: ((view.frame.width/2) - ((sizeWidth+40)/2)), y: (view.frame.height) - sizeHeight - 40, width: sizeWidth+40, height: sizeHeight+40))
//        progress.progressThickness = 0.2
//        progress.trackThickness = 0.7
//        progress.clockwise = true
//        progress.startAngle = 270
//        progress.gradientRotateSpeed = 2
//        progress.roundedCorners = true
//        progress.glowMode = .Forward
//        progress.setColors(UIColor(hex:0xFF5E00) ,UIColor(hex:0xFF7300), UIColor(hex:0xffbc00))
//        progress.hidden = true
//        view.addSubview(progress)
//    }
    
    func showUI() {
        if !uiLocked {
            uiWrapper.isHidden = false
        }
    }
    
    
    func hideUI() {
        if !uiLocked {
            uiWrapper.isHidden = true
        }
    }
    
    func lockUI() {
        uiLocked = true
    }
    
    func unlockUI() {
        uiLocked = false
    }
    
    dynamic fileprivate func tapCameraButton() {
        delegate?.onTapCameraButton()
    }
    
    dynamic fileprivate func touchStartCameraButton() {
        delegate?.onTouchStartCameraButton()
    }
    
    dynamic fileprivate func touchEndCameraButton() {
        delegate?.onTouchEndCameraButton()
    }
}


class RecordButton: UIButton {
    
    fileprivate var touched = false
    
    fileprivate let progressLayer = CALayer()
    fileprivate let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    var icon: UIImage = UIImage(named:"camera_icn")! {
        didSet {
            setImage(icon, for: UIControlState())
        }
    }
    
    var iconColor: UIColor = .white {
        didSet {
            setTitleColor(iconColor.alpha(loading ? 0 : 1), for: UIControlState())
        }
    }
    
    var loading = false {
        didSet {
            if loading {
                loadingView.startAnimating()
            } else {
                loadingView.stopAnimating()
            }
            
            setTitleColor(titleColor(for: UIControlState())!.alpha(loading ? 0 : 1), for: UIControlState())
            
            isUserInteractionEnabled = !loading
        }
    }
    
    var progressLocked = false {
        didSet {
            if !progressLocked {
                let tmp = progress
                progress = tmp
            }
        }
    }
    
    var progress: CGFloat? = nil {
        didSet {
            if !progressLocked {
                if let progress = progress {
                    backgroundColor = UIColor.clear
                    loading = progress != 1
                } else {
                    backgroundColor = UIColor.clear
                    loading = false
                }
                
                layoutSubviews()
            }
        }
    }
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        layer.addSublayer(progressLayer)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        backgroundColor = UIColor.clear
        clipsToBounds = true
        
        layer.cornerRadius = bounds.size.width * 0.5
        
        setTitleColor(.white, for: UIControlState())
        // TOODO: Icomoon!
        //titleLabel?.font = UIFont.iconOfSize(33)
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

class TabButton: UIButton {
    
    enum Color { case light, dark }
    
    var title: String = "" {
        didSet {
            text.text = title
        }
    }
    
    // Todo: Add Icomoon
    //var icon: Icon = .Cancel {
    //    didSet {
    //        setTitle(String.iconWithName(icon), for: UIControlState())
    //    }
    //}
    
    var color: Color = .dark {
        didSet {
            let actualColor = color == .dark ? .white : UIColor(0x919293)
            setTitleColor(actualColor, for: UIControlState())
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
            
            setTitleColor(titleColor(for: UIControlState())!.alpha(loading ? 0 : 1), for: UIControlState())
            
            isUserInteractionEnabled = !loading
        }
    }
    
    //    private let activeBorderLayer = CALayer()
    
    fileprivate let text = UILabel()
    fileprivate let loadingView = UIActivityIndicatorView()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(.white, for: UIControlState())
        // TODO: Icomoon
        //titleLabel?.font = UIFont.iconOfSize(28)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        text.font = UIFont.displayOfSize(9, withType: .Light)
        text.textColor = .white
        text.textAlignment = .center
        addSubview(text)
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
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
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let margin: CGFloat = 10
        let area = bounds.insetBy(dx: -margin, dy: -margin)
        return area.contains(point)
    }
    
}

protocol TabControllerDelegate {
    var tabController: TabViewController? { get }
    func jumpToTop()
    func scrollToOptograph(_ optographID: UUID)
    func onTouchStartCameraButton()
    func onTouchEndCameraButton()
    func onTapCameraButton()
    func onTapLeftButton()
    func onTapRightButton()
    func onTouchOneRingButton()
    func onTouchThreeRingButton()
}

extension TabControllerDelegate {
    func scrollToOptograph(_ optographID: UUID) {}
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
        case .idle:
            tabController!.leftViewController.cleanup()
            self.tabController!.leftViewController.pushViewController(CameraOverlayVC(), animated: false)
            
        case .stitching(_):
            let alert = UIAlertController(title: "Rendering in progress", message: "Please wait until your last image has finished rendering.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in return }))
            tabController?.leftViewController.present(alert, animated: true, completion: nil)
        case let .stitchingFinished(optographID):
            scrollToOptograph(optographID)
            PipelineService.stitchingStatus.value = .idle
        case .uninitialized: ()
        }
    }
}

extension UIViewController {
    var tabController: TabViewController? {
        return navigationController?.parent as? TabViewController
    }
    
    func updateTabs() {
        
        tabController!.cameraButton.icon = UIImage(named:"camera_icn")!
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
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}

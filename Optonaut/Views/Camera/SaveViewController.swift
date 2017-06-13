//
//  EditProfileViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import KMPlaceholderTextView
import Mixpanel
import Async
import AVFoundation
import SceneKit
import ObjectMapper
import FBSDKLoginKit
import TwitterKit
import SpriteKit

class SaveViewController: UIViewController, RedNavbar {
    
    fileprivate let viewModel: SaveViewModel
    
    fileprivate var touchRotationSource: TouchRotationSource!
    fileprivate var renderDelegate: SphereRenderDelegate!
    fileprivate var scnView: SCNView!
    fileprivate let dragTextView = UILabel()
    fileprivate let dragIconView = UILabel()
    
    // subviews
    fileprivate let scrollView = ScrollView()
    fileprivate let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    
    fileprivate var placeholderImage: SKTexture?
    
    fileprivate let readyNotification = NotificationSignal<Void>()
    
    required init(recorderCleanup: SignalProducer<UIImage, NoError>) {
        
        let (placeholderSignal, placeholderSink) = Signal<UIImage, NoError>.pipe()
        
        viewModel = SaveViewModel(placeholderSignal: placeholderSignal, readyNotification: readyNotification)
        
        super.init(nibName: nil, bundle: nil)
        
        recorderCleanup
            .start(on: QueueScheduler(qos: .background, name: "RecorderQueue", targeting: nil))
            .on(event: { event in
                placeholderSink.action(event)
            })
            .map { SKTexture(image: $0) }
            .observeOnMain()
            .on(
                completed: { [weak self] in
                    print("stitching finished")
                    self?.viewModel.stitcherFinished.value = true
                },
                value: { [weak self] image in
                    if let renderDelegate = self?.renderDelegate {
                        renderDelegate.texture = image
                    } else {
                        self?.placeholderImage = image
                    }
                }
            )
            .start()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readyNotification.notify(())
        
        title = "RENDERING 360 IMAGE"
        
        var cancelButton = UIImage(named: "camera_back_button")
        
        cancelButton = cancelButton?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: cancelButton, style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.cancel))
        
        view.backgroundColor = .white
        
        let scnFrame = CGRect(x: 0, y: 0, width: view.frame.width, height: 0.46 * view.frame.width)
        if #available(iOS 9.0, *) {
            scnView = SCNView(frame: scnFrame, options: [SCNView.Option.preferredRenderingAPI.rawValue as String: SCNRenderingAPI.openGLES2.rawValue])
        } else {
            scnView = SCNView(frame: scnFrame)
        }
        
        let hfov: Float = 80
        
        touchRotationSource = TouchRotationSource(sceneSize: scnView.frame.size, hfov: hfov)
        touchRotationSource.dampFactor = 0.9999
        touchRotationSource.phiDamp = 0.003
    
        renderDelegate = SphereRenderDelegate(rotationMatrixSource: touchRotationSource, width: scnView.frame.width, height: scnView.frame.height, fov: Double(hfov))
        
        scnView.scene = renderDelegate.scene
        scnView.delegate = renderDelegate
        scnView.backgroundColor = .black
        scnView.isPlaying = UIDevice.current.deviceType != .simulator
        scrollView.addSubview(scnView)
        
        renderDelegate.texture = placeholderImage
        
        blurView.frame = scnView.frame
        
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.frame = blurView.frame
        gradientMaskLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor]
        gradientMaskLayer.locations = [0.0, 0.4, 0.6, 1.0]
        gradientMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientMaskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        blurView.layer.addSublayer(gradientMaskLayer)
        blurView.layer.mask = gradientMaskLayer
        scrollView.addSubview(blurView)
        
        let dragText = "Move the image to select your favorite spot"
        let dragTextWidth = calcTextWidth(dragText, withFont: .displayOfSize(13, withType: .Light))
        dragTextView.text = dragText
        dragTextView.textAlignment = .center
        dragTextView.font = UIFont.displayOfSize(13, withType: .Light)
        dragTextView.textColor = .white
        dragTextView.layer.shadowColor = UIColor.black.cgColor
        dragTextView.layer.shadowRadius = 5
        dragTextView.layer.shadowOffset = CGSize.zero
        dragTextView.layer.shadowOpacity = 1
        dragTextView.layer.masksToBounds = false
        dragTextView.layer.shouldRasterize = true
        dragTextView.frame = CGRect(x: view.frame.width / 2 - dragTextWidth / 2 + 15, y: 0.46 * view.frame.width - 40, width: dragTextWidth, height: 20)
        scrollView.addSubview(dragTextView)
        
        // TODO: Icomoon
        //dragIconView.text = String.iconWithName(.DragImage)
        //dragIconView.font = UIFont.iconOfSize(20)
        dragIconView.textColor = .white
        dragIconView.frame = CGRect(x: -30, y: 0, width: 20, height: 20)
        dragTextView.addSubview(dragIconView)
        
        scrollView.scnView = scnView
        view.addSubview(scrollView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SaveViewController.dismissKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
        
        viewModel.isReadyForSubmit.producer.startWithValues { [weak self] isReady in
            self?.tabController!.cameraButton.loading = !isReady
        }
        
        viewModel.isReadyForStitching.producer
            .filter(isTrue)
            .startWithValues { [weak self] _ in
                if let strongSelf = self {
                    PipelineService.stitch(strongSelf.viewModel.optograph.ID)
                }
            }
    }
    func readyToSubmit(){
        if viewModel.isReadyForSubmit.value {
            submit(true)
        }
    }
    func postLaterAction(){
        if viewModel.isReadyForSubmit.value {
            submit(false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let contentHeight = 0.46 * view.frame.width + 85 + 68 + 120 + 126
        let scrollEnabled = contentHeight > view.frame.height
        scrollView.contentSize = CGSize(width: view.frame.width, height: scrollEnabled ? contentHeight : view.frame.height)
        scrollView.isScrollEnabled = scrollEnabled
        
        scrollView.fillSuperview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SaveViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SaveViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.fontDisplay(14, withType: .Regular),
            NSForegroundColorAttributeName: UIColor(hex:0xFF5E00),
        ]
        
        tabController!.delegate = self
        tabController!.cameraButton.progressLocked = true
        
        Mixpanel.sharedInstance()?.timeEvent("View.CreateOptograph")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        tabController!.cameraButton.progressLocked = false
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        UIApplication.shared.setStatusBarHidden(false, with: .none)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Mixpanel.sharedInstance()?.track("View.CreateOptograph")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let touch = touches.first {
            let point = touch.location(in: scnView)
            touchRotationSource.touchStart(CGPoint(x: point.x, y: 0))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        dragTextView.isHidden = true
        touchRotationSource.dampFactor = 0.9
        
        if let touch = touches.first {
            let point = touch.location(in: scnView)
            touchRotationSource.touchMove(CGPoint(x: point.x, y: 0))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        if touches.count == 1 {
            touchRotationSource.touchEnd()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        super.touchesCancelled(touches!, with: event)
        
        if touches?.count == 1 {
            touchRotationSource.touchEnd()
        }
    }
    
    dynamic fileprivate func keyboardWillShow(_ notification: Notification) {
        scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height)
    }
    
    dynamic fileprivate func keyboardWillHide(_ notification: Notification) {
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    dynamic fileprivate func cancel() {
        let confirmAlert = UIAlertController(title: "Discard Moment?", message: "If you go back now, the recording will be discarded.", preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
            PipelineService.stopStitching()
            LoadingIndicatorView.show("Discarding..")
            self.viewModel.isReadyForSubmit.producer.skipRepeats().startWithValues { val in
                if val{
                    LoadingIndicatorView.hide()
                    self.viewModel.deleteOpto()
                    self.navigationController!.popViewController(animated: true)
                }
            }
        }))
        confirmAlert.addAction(UIAlertAction(title: "Keep", style: .cancel, handler: nil))
        navigationController!.present(confirmAlert, animated: true, completion: nil)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    fileprivate func submit(_ shouldBePublished: Bool) {
        viewModel.submit(shouldBePublished, directionPhi: Double(touchRotationSource.phi), directionTheta: Double(touchRotationSource.theta))
            .observeOnMain()
            .on(
                started: { [weak self] in
                    self?.tabController!.cameraButton.loading = true
                },
                completed: { [weak self] in
                    Mixpanel.sharedInstance()?.track("Action.CreateOptograph.Post")
                    self?.navigationController!.popViewController(animated: true)
                }
            )
            .start()
    }
}


// MARK: - UITextViewDelegate
extension SaveViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            view.endEditing(true)
            return false
        }
        return true
    }
    
}


// MARK: - TabControllerDelegate
extension SaveViewController: TabControllerDelegate {
    
    func onTapCameraButton() {
        if viewModel.isReadyForSubmit.value {
            submit(true)
        }
    }
}

private class ScrollView: UIScrollView {
    
    weak var scnView: SCNView!
    
    fileprivate override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return point.y > scnView.height
    }
}

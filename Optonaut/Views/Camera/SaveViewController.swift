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
    
    // subviews
    fileprivate let scrollView = ScrollView()
    fileprivate let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    fileprivate let dragTextView = UILabel()
    fileprivate let dragIconView = UILabel()
    fileprivate let locationView: LocationView
    fileprivate let textInputView = UITextView()
    fileprivate let textPlaceholderView = UILabel()
    fileprivate let shareBackgroundView = UIView()
    fileprivate let facebookSocialButton = SocialButton()
    fileprivate let twitterSocialButton = SocialButton()
    fileprivate let instagramSocialButton = SocialButton()
    fileprivate let moreSocialButton = SocialButton()
    fileprivate var placeholderImage: SKTexture?
    
    fileprivate let readyNotification = NotificationSignal<Void>()
    
    required init(recorderCleanup: SignalProducer<UIImage, NoError>) {
        
        let (placeholderSignal, placeholderSink) = Signal<UIImage, NoError>.pipe()
        
        viewModel = SaveViewModel(placeholderSignal: placeholderSignal, readyNotification: readyNotification)
        
        locationView = LocationView(isOnline: viewModel.isOnline)
        
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
        
        var privateButton = UIImage(named: "privacy_me")
        var publicButton = UIImage(named: "privacy_world")
        var cancelButton = UIImage(named: "camera_back_button")
        
        privateButton = privateButton?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        publicButton = publicButton?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
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
        
        locationView.didSelectLocation = { [weak self] placeID in
            self?.viewModel.placeID.value = placeID
        }
        locationView.isHidden = true
        scrollView.addSubview(locationView)
        
        textPlaceholderView.font = UIFont.textOfSize(12, withType: .Regular)
        textPlaceholderView.text = "Tell something about what you see..."
        textPlaceholderView.textColor = UIColor.DarkGrey.alpha(0.4)
        textPlaceholderView.isHidden = true
        textPlaceholderView.rac_hidden <~ viewModel.text.producer.map(isNotEmpty)
        textInputView.addSubview(textPlaceholderView)
        
        textInputView.font = UIFont.textOfSize(12, withType: .Regular)
        textInputView.textColor = UIColor(0x4d4d4d)
        textInputView.textContainer.lineFragmentPadding = 0 // remove left padding
        textInputView.textContainerInset = UIEdgeInsets.zero // remove top padding
        textInputView.returnKeyType = .done
        textInputView.delegate = self
        textInputView.isHidden = true
        textInputView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 14, right: 0)
        textInputView.textContainerInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        // TODO
        //textInputView.rac_text.toSignalProducer().startWithNext { [weak self] val in
        //    self?.viewModel.text.value = val as! String
        //}
        textInputView.removeConstraints(textInputView.constraints)
        scrollView.addSubview(textInputView)
    
        scrollView.scnView = scnView
        view.addSubview(scrollView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SaveViewController.dismissKeyboard))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
        
        viewModel.isReadyForSubmit.producer.startWithValues { [weak self] isReady in
            self?.tabController!.cameraButton.loading = !isReady
            
//            if isReady {
//                self?.tabController!.cameraButton.icon = UIImage(named:"upload_next")!
//            }
//            
        }
        
        viewModel.isReadyForStitching.producer
            .filter(isTrue)
            .startWithValues { [weak self] _ in
                if let strongSelf = self {
                    PipelineService.stitch(strongSelf.viewModel.optographBox.model.ID)
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
        locationView.alignAndFillWidth(align: .underCentered, relativeTo: scnView, padding: 0, height: 68)
        textInputView.alignAndFillWidth(align: .underCentered, relativeTo: locationView, padding: 0, height: 85)
        textPlaceholderView.anchorInCorner(.topLeft, xPad: 16, yPad: 7, width: 250, height: 20)
        
        if scrollEnabled {
            shareBackgroundView.align(.underCentered, relativeTo: textInputView, padding: 0, width: view.frame.width + 2, height: 120)
        } else {
            shareBackgroundView.anchorInCorner(.bottomLeft, xPad: -1, yPad: 126, width: view.frame.width + 2, height: 120)
        }
        
        let socialPadX = (view.frame.width - 2 * 120) / 3
        facebookSocialButton.anchorInCorner(.topLeft, xPad: socialPadX, yPad: 10, width: 120, height: 23)
        twitterSocialButton.anchorInCorner(.topRight, xPad: socialPadX, yPad: 10, width: 120, height: 23)
        instagramSocialButton.anchorInCorner(.bottomLeft, xPad: socialPadX, yPad: 30, width: 120, height: 23)
        moreSocialButton.anchorInCorner(.bottomRight, xPad: socialPadX, yPad: 30, width: 120, height: 23)
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
        
        // needed if user re-enabled location via Settings.app
        locationView.reloadLocation()
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
    
    dynamic fileprivate func togglePrivate() {
        let settingsSheet = UIAlertController(title: "Set Visibility", message: "Who should be able to see your moment?", preferredStyle: .actionSheet)
        
        settingsSheet.addAction(UIAlertAction(title: "Everybody (Default)", style: .default, handler: { [weak self] _ in
            self?.viewModel.isPrivate.value = false
        }))
        
        settingsSheet.addAction(UIAlertAction(title: "Just me", style: .destructive, handler: { [weak self] _ in
            self?.viewModel.isPrivate.value = true
        }))
        
        settingsSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in return }))
        
        navigationController?.present(settingsSheet, animated: true, completion: nil)
    }
    
    fileprivate func signupAlert() {
        let alert = UIAlertController(title: "Login Needed", message: "In order to share your moment you need to create an account. Your image won't be lost and can be shared afterwards.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { _ in return }))
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func offlineAlert() {
        let alert = UIAlertController(title: "No Network Connection", message: "In order to share your moment you need a network connection. Your image won't be lost and can still be shared later.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { _ in return }))
        present(alert, animated: true, completion: nil)
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

private class LocationViewModel {
    
    enum State { case disabled, selection }
    
    let locations = MutableProperty<[GeocodePreview]>([])
    let selectedLocation = MutableProperty<Int?>(nil)
    let state: MutableProperty<State>
    
    let locationSignal = NotificationSignal<Void>()
    let locationEnabled = MutableProperty<Bool>(false)
    let locationLoading = MutableProperty<Bool>(false)
    
    var locationPermissionTimer: Timer?
    
    weak var isOnline: MutableProperty<Bool>!
    
    init(isOnline: MutableProperty<Bool>) {
        self.isOnline = isOnline
        
        locationEnabled.value = LocationService.enabled
        
        state = MutableProperty(LocationService.enabled ? .selection : .disabled)
        
        locationSignal.signal
            .map { _ in self.locationEnabled.value }
            .filter(identity)
            .flatMap(.latest) { [weak self] _ in
                LocationService.location()
                    .take(first: 1)
                    .on(value: { (lat, lon) in
                        self?.locationLoading.value = true
                        self?.selectedLocation.value = nil
//                        var location = Location.newInstance()
//                        location.latitude = lat
//                        location.longitude = lon
                    })
                    .ignoreError()
            }
            .flatMap(.latest) { (lat, lon) -> SignalProducer<[GeocodePreview], NoError> in
                  return SignalProducer(value: [GeocodePreview(name: "Use location (\(lat.rounded()), \(lon.rounded()))")])
                
            }
            .observe { [weak self] locations in
                self?.locationLoading.value = false
                self?.locations.value = locations.value!
            }
        
    }
    
    deinit {
        locationPermissionTimer?.invalidate()
    }
    
    func enableLocation() {
        locationPermissionTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(LocationViewModel.checkLocationPermission), userInfo: nil, repeats: true)
        LocationService.askPermission()
    }
    
    dynamic fileprivate func checkLocationPermission() {
        let enabled = LocationService.enabled
        state.value = enabled ? .selection : .disabled
        if locationPermissionTimer != nil && enabled {
            locationEnabled.value = true
            locationSignal.notify(())
            locationPermissionTimer?.invalidate()
            locationPermissionTimer = nil
        }
    }
}

private struct GeocodePreview: Mappable {
    var placeID = ""
    var name = ""
    var vicinity = ""
    
    init(name: String) {
        self.name = name
    }
    
    init() {}
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        placeID  <- map["place_id"]
        name     <- map["name"]
        vicinity <- map["vicinity"]
    }
}

private class LocationCollectionViewCell: UICollectionViewCell {
    
    fileprivate let textView = UILabel()
    
    var text = "" {
        didSet {
            textView.text = text
        }
    }
    
    // TODO
    //var isSelected = false {
    //    didSet {
    //        contentView.backgroundColor = isSelected ? UIColor(0x5f5f5f) : UIColor(0xefefef)
    //        textView.textColor = isSelected ? .white : UIColor(0x5f5f5f)
    //    }
    //}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 4
        
        textView.font = UIFont.displayOfSize(11, withType: .Semibold)
        textView.textColor = UIColor(0x5f5f5f)
        contentView.addSubview(textView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        
        textView.fillSuperview(left: 10, right: 10, top: 0, bottom: 0)
    }
    
}

private class LocationView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    fileprivate let bottomBorder = CALayer()
    fileprivate let leftIconView = UIImageView()
    fileprivate let statusText = UILabel()
    fileprivate let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
    fileprivate let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    var didSelectLocation: ((String?) -> ())?
    
    var viewModel: LocationViewModel!
    
    fileprivate var locations: [GeocodePreview] = []
    
    convenience init(isOnline: MutableProperty<Bool>) {
        self.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        viewModel = LocationViewModel(isOnline: isOnline)
        
        bottomBorder.backgroundColor = UIColor(0xe6e6e6).cgColor
        layer.addSublayer(bottomBorder)
        
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = .horizontal
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(LocationCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsSelection = true
        collectionView.rac_hidden <~ viewModel.locationLoading
        collectionView.isHidden = true
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 16)
        viewModel.locations.producer.startWithValues { [weak self] locations in
            self?.locations = locations
            self?.collectionView.reloadData()
        }
        viewModel.selectedLocation.producer.startWithValues { [weak self] _ in self?.collectionView.reloadData() }
        addSubview(collectionView)
        
        loadingIndicator.rac_animating <~ viewModel.locationLoading
        loadingIndicator.hidesWhenStopped = true
        addSubview(loadingIndicator)
        
        leftIconView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LocationView.didTap)))
        leftIconView.isUserInteractionEnabled = true
        leftIconView.image = UIImage(named:"location_pin")
        leftIconView.isHidden = true
        addSubview(leftIconView)
        
        statusText.font = UIFont.displayOfSize(13, withType: .Semibold)
        statusText.textColor = UIColor(0x919293)
        statusText.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LocationView.didTap)))
        statusText.isUserInteractionEnabled = true
        statusText.rac_hidden <~ viewModel.locationEnabled
        statusText.text = "Add location"
        statusText.isHidden = true
        addSubview(statusText)
    }
    
    fileprivate override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bottomBorder.frame = CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1)
        leftIconView.frame = CGRect(x: 16, y: 22, width: leftIconView.image!.size.width, height: leftIconView.image!.size.height)
        statusText.frame = CGRect(x: 54, y: 22, width: 200, height: 24)
        loadingIndicator.frame = CGRect(x: 54, y: 20, width: 28, height: 28)
        collectionView.frame = CGRect(x: 54, y: 0, width: frame.width - 54, height: 68)
    }
    
    dynamic fileprivate func didTap() {
        if viewModel.locationEnabled.value {
            reloadLocation()
        } else {
            enableLocation()
        }
    }
    
    dynamic fileprivate func enableLocation() {
        viewModel.enableLocation()
    }
    
    dynamic func reloadLocation() {
        didSelectLocation?(nil)
        viewModel.locationSignal.notify(())
    }
    
    dynamic fileprivate func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! LocationCollectionViewCell
        let location = locations[indexPath.row]
        cell.text = "\(location.name)"
        cell.isSelected = viewModel.selectedLocation.value == indexPath.row
        return cell
    }

    dynamic func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    dynamic func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locations.count
    }
    
    dynamic fileprivate func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let location = locations[indexPath.row]
        let text = "\(location.name)"
        return CGSize(width: calcTextWidth(text, withFont: .displayOfSize(11, withType: .Semibold)) + 20, height: 28)
    }
    
    dynamic fileprivate func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if viewModel.selectedLocation.value == indexPath.row {
            viewModel.selectedLocation.value = nil
            didSelectLocation?(nil)
        } else {
            viewModel.selectedLocation.value = indexPath.row
            didSelectLocation?(locations[indexPath.row].placeID)
        }
    }
    
}

private class SocialButton: UIView {
    
    fileprivate let loadingView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    fileprivate let textView = UILabel()
    fileprivate var touched = false
    fileprivate var iconView2 = UIImageView()
    
    var text = "" {
        didSet {
            textView.text = text
        }
    }
    
    var icon2:UIImage = UIImage(named:"facebook_save_active")! {
        didSet {
            iconView2.image = icon2
        }
    }
    
    var color = UIColor.Accent {
        didSet {
            updateColors()
        }
    }
    
    enum State { case selected, unselected, loading }
    
    var state: State = .unselected {
        didSet {
            updateColors()
        }
    }
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        loadingView.hidesWhenStopped = true
        addSubview(loadingView)
        
        textView.font = UIFont.displayOfSize(16, withType: .Semibold)
        addSubview(textView)
        
        addSubview(iconView2)
        
        updateColors()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let iconHeight = UIImage(named:"facebook_save_active")!.size.height
        let iconWidth = UIImage(named:"facebook_save_active")!.size.width
        
        loadingView.frame = CGRect(x: 0, y: 0, width: iconHeight, height: iconHeight)
        textView.frame = CGRect(x: 45, y: 10, width: 77, height: 17)
        
        iconView2.frame = CGRect(x: 0,y: 0,width: iconWidth,height: iconHeight)
    }
    
    fileprivate override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touched = true
        updateColors()
    }
    
    fileprivate override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        super.touchesCancelled(touches!, with: event)
        touched = false
        updateColors()
    }
    
    fileprivate override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touched = false
        updateColors()
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let margin: CGFloat = 5
        let area = bounds.insetBy(dx: -margin, dy: -margin)
        return area.contains(point)
    }
    
    fileprivate func updateColors() {
        if state == .loading {
            loadingView.startAnimating()
            iconView2.isHidden = true
        } else {
            loadingView.stopAnimating()
            iconView2.isHidden = false
        }
        
        var textColor = UIColor(0x919293)
        if touched {
            textColor = color.alpha(0.7)
        } else if state == .selected {
            textColor = color
        }
        
        textView.textColor = textColor
    }
}

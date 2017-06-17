//
//  CollectionViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/12/2015.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveSwift
import SpriteKit
import Async
import CoreBluetooth
import SwiftyUserDefaults

typealias Direction = (phi: Float, theta: Float)

protocol OptographCollectionViewModel {
    var isActive: MutableProperty<Bool> { get }
    var results: MutableProperty<[Optograph]> { get }
    func refresh()
}


fileprivate let queue = DispatchQueue(label: "collection_view", attributes: [])
fileprivate let queueScheduler = QueueScheduler(qos: .background, name: "collection_view", targeting: queue)

var bt: BLEDiscovery!
var btMotorControl : MotorControl?

let remoteManualNotificationKey = "meyer.remoteManual"
let remoteMotorNotificationKey = "meyer.remoteMotor"
let stitchingFinishedNotificationKey = "meyer.stitchingFinished"
let deletedOptographNotificationKey = "meyer.deletedOptograph"
let didConnectMotorNotificationKey = "meyer.didConnectMotor"

class OptographCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, RedNavbar {

    let dataBase = DataBase.sharedInstance
    
    fileprivate let viewModel: FeedOptographCollectionViewModel
    fileprivate let imageCache: CollectionImageCache
    fileprivate let overlayDebouncer: Debouncer
    
    fileprivate var optographIDs: [UUID] = []
    fileprivate var optographDirections: [UUID: Direction] = [:]
    
    fileprivate let refreshControl = UIRefreshControl()
    fileprivate let overlayView = OverlayView()
    
    fileprivate let uiHidden = MutableProperty<Bool>(false)
    fileprivate var overlayIsAnimating = false
    fileprivate var isVisible = false

    //bluetoothCode
    var btService : BLEService?
    var btDevices = [CBPeripheral]()

    init(viewModel: FeedOptographCollectionViewModel) {
        self.viewModel = viewModel
        
        overlayDebouncer = Debouncer(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive), delay: 0.01)
        
        let textureSize = getTextureWidth(UIScreen.main.bounds.width, hfov: HorizontalFieldOfView)
        imageCache = CollectionImageCache(textureSize: textureSize)
        
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        imageCache.onMemoryWarning()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.updateOptographCollection(_:)), name: NSNotification.Name(rawValue: stitchingFinishedNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshDataSourceForCollectionView(_:)), name: NSNotification.Name(rawValue: deletedOptographNotificationKey), object: nil)

        let cardboardButton = UIButton()
        cardboardButton.setBackgroundImage(UIImage(named: "vr_icon"), for: UIControlState())
        cardboardButton.frame = CGRect(x: 0, y: -2, width: 35, height: 24)
        cardboardButton.isUserInteractionEnabled = true
        cardboardButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OptographCollectionViewController.showCardboardAlert)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cardboardButton)
        
        refreshControl.bounds = CGRect(x: refreshControl.bounds.origin.x, y: 5, width: refreshControl.bounds.width, height: refreshControl.bounds.height)
        collectionView!.addSubview(refreshControl)
        
        // Register cell classes
        collectionView!.register(OptographCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        collectionView!.delegate = self
        
        collectionView!.isPagingEnabled = true
        
        automaticallyAdjustsScrollViewInsets = false
        
        collectionView!.delaysContentTouches = false
        
        edgesForExtendedLayout = UIRectEdge()

        optographIDs = self.viewModel.getOptographIds()

        let topOffset = navigationController!.navigationBar.frame.height + 20
        overlayView.frame = CGRect(x: 0, y: topOffset, width: view.frame.width, height: view.frame.height - topOffset)
        overlayView.uiHidden = uiHidden
        overlayView.navigationController = navigationController as? NavigationController
        overlayView.parentViewController = self
        overlayView.rac_hidden <~ uiHidden
        view.addSubview(overlayView)
        
        uiHidden.producer.startWithValues { [weak self] hidden in
            self?.navigationController?.setNavigationBarHidden(hidden, animated: false)
            
            self?.collectionView!.isScrollEnabled = !hidden
            
            if hidden {
                self?.tabController?.hideUI()
            } else {
                self?.tabController?.showUI()
            }
        }
        
        PipelineService.stitchingStatus.producer
            .observeOnMain()
            .startWithValues { [weak self] status in
                switch status {
                case .stitchingFinished(_):
                    self?.collectionView!.reloadData()
                default:
                    break
                }
        }

        if bt == nil {
            bt = BLEDiscovery(onDeviceFound: onDeviceFound, onDeviceConnected: onDeviceConnected, services: [MotorControl.BLEServiceUUID])
        } else {
            if !bt.connectedPeripherals.isEmpty {
                btService = BLEService(initWithPeripheral: bt.connectedPeripherals[0], onServiceConnected: onServiceConnected, bleService: MotorControl.BLEServiceUUID, bleCharacteristic: [MotorControl.BLECharacteristicUUID, MotorControl.BLECharacteristicResponseUUID])
                btService?.startDiscoveringServices()
            } else {
                bt.startScanning()
            }
        }

    }

    func registerObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.remoteManual), name: NSNotification.Name(rawValue: remoteManualNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.remoteMotor), name: NSNotification.Name(rawValue: remoteMotorNotificationKey), object: nil)
    }

    func onDeviceFound(device: CBPeripheral, name: NSString) {
        self.btDevices = self.btDevices + [device]
        bt.connectPeripheral(btDevices[0])
    }

    func onDeviceConnected(device: CBPeripheral) {
        btService = BLEService(initWithPeripheral: device, onServiceConnected: onServiceConnected, bleService: MotorControl.BLEServiceUUID, bleCharacteristic: [MotorControl.BLECharacteristicUUID, MotorControl.BLECharacteristicResponseUUID])
        btService?.startDiscoveringServices()
    }

    func onServiceConnected(service: CBService) {
        btMotorControl = MotorControl(s: service, p: service.peripheral, allowCommandInterrupt: true)
        NotificationCenter.default.post(name: Notification.Name(rawValue: didConnectMotorNotificationKey), object: self, userInfo: nil)
        registerObserver()
    }

    func remoteManual() {
        Defaults[.SessionUseMultiRing] = false
        record()
    }

    func remoteMotor() {
        Defaults[.SessionUseMultiRing] = true
        record()
    }

    func record() {
        NotificationCenter.default.removeObserver(self)
        Defaults[.SessionMotor] = true
        tabController!.cameraButton.isHidden = true
        if bt.connectedPeripherals.isEmpty {
            self.tabController!.cameraButton.isHidden = false
            let confirmAlert = UIAlertController(title: "Error!", message: "Motor recordings require Bluetooth turned ON and paired to any DSCVR Orbit Motor.", preferredStyle: .alert)
            confirmAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(confirmAlert, animated: true, completion: nil)
        } else {
            self.navigationController?.pushViewController(CameraViewController(), animated: false)
            let cvc = self.navigationController?.viewControllers[1] as! CameraViewController
            cvc.motorControl = btMotorControl
            cvc.motionManager = cvc.motorControl
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        uiHidden.value = false
        overlayView.alpha = 0
        
        if !optographIDs.isEmpty {
            lazyFadeInOverlay(delay: 0.3)
        }
        
        viewModel.isActive.value = true
        
        CoreMotionRotationSource.Instance.start()
        
        view.bounds = UIScreen.main.bounds
        
        RotationService.sharedInstance.rotationEnable()
        
        if let indexPath = collectionView!.indexPathsForVisibleItems.first, let cell = collectionView!.cellForItem(at: indexPath) {
            collectionView(collectionView!, willDisplay: cell, forItemAt: indexPath)
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // TODO - remove as soon as correct disposal is implemented.
        // imageCache.reset()
        
        RotationService.sharedInstance.rotationDisable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        isVisible = true
        
        if !optographIDs.isEmpty {
            lazyFadeInOverlay(delay: 0)
        }
        
        tabController!.delegate = self
        
        updateNavbarAppear()
        
        updateTabs()
        
        tabController!.showUI()
        
        if let rotationSignal = RotationService.sharedInstance.rotationSignal {
            rotationSignal
                .skipRepeats()
                .filter(values: [.landscapeLeft, .landscapeRight])
                .take(first: 1)
                .observe(on: UIScheduler())
                .observeValues { [weak self] orientation in self?.pushViewer(orientation) }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        isVisible = false
        
        CoreMotionRotationSource.Instance.stop()
        
        viewModel.isActive.value = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.frame = UIScreen.main.bounds
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return optographIDs.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! OptographCollectionViewCell
        
        cell.uiHidden = uiHidden
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return UIScreen.main.bounds.size
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? OptographCollectionViewCell else {
            return
        }
        
        let optographID = optographIDs[indexPath.row]
        
        cell.direction = (phi: Float(M_PI_2), theta: Float(-M_PI_2))//optographDirections[optographID]!
        cell.willDisplay()
        
        let cubeImageCache = imageCache.get(indexPath.row, optographID: optographID, side: .left)
        cell.setCubeImageCache(cubeImageCache)
        
        cell.id = indexPath.row
        
        if StitchingService.isStitching() {
            imageCache.resetExcept(indexPath.row)
        } else {
            for i in [-2, -1, 1, 2] where indexPath.row + i > 0 && indexPath.row + i < optographIDs.count {
                let id = optographIDs[indexPath.row + i]
                let cubeIndices = cell.getVisibleAndAdjacentPlaneIndices((phi: Float(M_PI_2), theta: Float(-M_PI_2))/*optographDirections[id]!*/)
                imageCache.touch(indexPath.row + i, optographID: id, side: .left, cubeIndices: cubeIndices)
            }
        }
        
        if overlayView.optographID == nil {
            overlayView.optographID = optographID
        }
        
        if isVisible {
            lazyFadeInOverlay(delay: 0)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! OptographCollectionViewCell
//        optographDirections[optographIDs[indexPath.row]] = cell.direction
        cell.didEndDisplay()

        DispatchQueue.main.async {
            self.imageCache.disable(indexPath.row)
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = view.frame.height
        let offset = scrollView.contentOffset.y
        
        if !overlayIsAnimating {
            let relativeOffset = offset.truncatingRemainder(dividingBy: height)
            let percentage = relativeOffset / height
            var opacity: CGFloat = 0
            if percentage > 0.8 || percentage < 0.2 {
                if scrollView.isDecelerating && overlayView.alpha == 0 {
                    overlayIsAnimating = true
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.2,
                                                   delay: 0,
                                                   options: [.allowUserInteraction],
                                                   animations: {
                                                    self.overlayView.alpha = 1
                            }, completion: nil)
                    }
                    return
                }
                
                let normalizedPercentage = percentage < 0.2 ? percentage : 1 - percentage
                opacity = -10 * normalizedPercentage + 2
            }
            
            overlayView.alpha = opacity
        }
        var overlayOptographID: UUID! = ""
        if (Int(round(offset / height)) < optographIDs.count) {
            overlayOptographID = optographIDs[Int(round(offset / height))]
        } else {
            return
        }

        if overlayOptographID != overlayView.optographID {
            overlayView.optographID = overlayOptographID
        }
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        overlayIsAnimating = false
        overlayView.layer.removeAllAnimations()
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        overlayIsAnimating = false
    }
    
    override func cleanup() {
        for cell in collectionView!.visibleCells.map({ $0 as! OptographCollectionViewCell }) {
            cell.forgetTextures()
        }
        
        imageCache.reset()
    }
    
    fileprivate func pushViewer(_ orientation: UIInterfaceOrientation) {
        guard let index = collectionView!.indexPathsForVisibleItems.first?.row else {
            return
        }
        
        let optograph = DataBase.sharedInstance.getOptograph(id: overlayView.optographID!)
        let viewerViewController = ViewerViewController(orientation: orientation, optograph: optograph)
        navigationController?.pushViewController(viewerViewController, animated: false)
    }
    
    fileprivate func lazyFadeInOverlay(delay: TimeInterval) {
        if overlayView.alpha == 0 && !overlayIsAnimating {
            overlayIsAnimating = true
            //            dispatch_async(dispatch_get_main_queue()) {
            UIView.animate(withDuration: 0.2,
                                       delay: delay,
                                       options: [.allowUserInteraction],
                                       animations: {
                                        self.overlayView.alpha = 1
                }, completion: { _ in
                    self.overlayIsAnimating = false
                }
            )
        }
    }
    
    dynamic fileprivate func showCardboardAlert() {
        let confirmAlert = UIAlertController(title: "Put phone in VR viewer", message: "Please turn your phone and put it into your VR viewer.", preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: "Continue", style: .cancel, handler: { _ in return }))
        navigationController?.present(confirmAlert, animated: true, completion: nil)
    }

    func updateOptographCollection(_ notification: NSNotification) {
        PipelineService.stitchingStatus.value = .idle
        Async.main {
            self.imageCache.reset()
            self.viewModel.refresh()
            self.optographIDs = self.viewModel.getOptographIds()
            self.collectionView!.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.remoteManual), name: NSNotification.Name(rawValue: remoteManualNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.remoteMotor), name: NSNotification.Name(rawValue: remoteMotorNotificationKey), object: nil)
    }

    func refreshDataSourceForCollectionView(_ notification: NSNotification) {
        if let optographID = notification.userInfo?["id"] as? String {
            let helperIDholder = self.viewModel.getOptographIds()
            dataBase.deleteOptograph(optographID: optographID)
            let index = helperIDholder.index(of: optographID)
            print("Index: \(index ?? -1)")
            let reversedIndex = helperIDholder.count - index! - 1
            print("ReversedIndex: \(reversedIndex)")
            imageCache.delete([reversedIndex])
            self.imageCache.reset()
            self.viewModel.refresh()
            optographIDs = self.viewModel.getOptographIds()
            print("OptographIDS after Delete:")
            print(optographIDs)
            if optographIDs.isEmpty {
                let row = helperIDholder.index(of: helperIDholder.first!)
                collectionView?.deleteItems(at: [IndexPath(row: row!, section: 0)])
                collectionView!.reloadData()
                overlayView.isHidden = true
            } else {
                scrollToOptograph("")
            }
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension OptographCollectionViewController: DefaultTabControllerDelegate {
    
    func jumpToTop() {
        viewModel.refresh()
        collectionView!.setContentOffset(CGPoint.zero, animated: true)
    }
    
    func scrollToOptograph(_ optographID: UUID) {
        self.collectionView!.reloadData()
//        let row = optographIDs.index(of: optographID)
        let row = optographIDs.index(of: optographIDs.first!)
        collectionView!.scrollToItem(at: IndexPath(row: row!, section: 0), at: .top, animated: true)
    }
    
}

private class OverlayViewModel {
    
    var optograph: Optograph!
    
    func bind(_ optographID: UUID) {
        
        optograph = DataBase.sharedInstance.getOptograph(id: optographID)
    }
}

private class OverlayView: UIView {
    
    fileprivate let viewModel = OverlayViewModel()
    
    weak var uiHidden: MutableProperty<Bool>!
    weak var navigationController: NavigationController?
    weak var parentViewController: UIViewController?
    
    var deleteCallback: (() -> ())?
    
    fileprivate var optographID: UUID? {
        didSet {
            if let optographID = optographID  {
                let optograph = DataBase.sharedInstance.getOptograph(id: optographID)
                
                viewModel.bind(optographID)
                
                dateView.text = optograph.createdAt.longDescription
            }
        }
    }
    
    fileprivate let whiteBackground = UIView()
    fileprivate let optionsButtonView = BoundingButton()
    fileprivate let dateView = UILabel()
    fileprivate let textView = BoundingLabel()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        whiteBackground.backgroundColor = UIColor.black.alpha(0.65)
        addSubview(whiteBackground)
        
        optionsButtonView.titleLabel?.font = UIFont.textOfSize(21, withType: .Regular)
        // TODO
        //optionsButtonView.setTitle(String.iconWithName(.more), for: UIControlState())
        optionsButtonView.setBackgroundImage(UIImage(named: "profile_delete_icn"), for: UIControlState())
        optionsButtonView.contentMode = .scaleAspectFit
        optionsButtonView.setTitleColor(UIColor(0xc6c6c6), for: UIControlState())
        optionsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OverlayView.didTapOptions)))
        addSubview(optionsButtonView)
        
        dateView.font = UIFont.displayOfSize(11, withType: .Regular)
        dateView.textColor = UIColor(0xbbbbbb)
        dateView.textAlignment = .right
        addSubview(dateView)
        
        textView.font = UIFont.displayOfSize(14, withType: .Regular)
        textView.textColor = .white
        textView.backgroundColor = .clear
        textView.isUserInteractionEnabled = true
        addSubview(textView)
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        whiteBackground.frame = CGRect(x: 0, y: 0, width: frame.width, height: 66)
        optionsButtonView.anchorInCorner(.topRight, xPad: 16, yPad: 21, width: 24, height: 24)
        dateView.anchorInCorner(.topRight, xPad: 46, yPad: 27, width: 100, height: 13)
        textView.anchorInCorner(.topLeft, xPad: 16, yPad: 25, width: self.width-dateView.frame.origin.x-10, height: textView.height)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
    
}

extension OverlayView: OptographOptions {
    
    dynamic func didTapOptions() {
        showOptions(viewModel.optograph.ID, deleteCallback: deleteCallback)
    }
    
}

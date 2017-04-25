//
//  CameraOverlayVC.swift
//  DSCVR
//
//  Created by robert john alkuino on 11/14/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import AVFoundation
import Async
import Photos
import SwiftyUserDefaults
import CoreBluetooth

var bt: BLEDiscovery!

class CameraOverlayVC: UIViewController {
    
    fileprivate let session = AVCaptureSession()
    fileprivate var videoDevice : AVCaptureDevice?
    fileprivate let manualButton = UIButton()
    fileprivate let motorButton = UIButton()
    fileprivate let motorLabel = UILabel()
    fileprivate let manualLabel = UILabel()
    fileprivate var backButton = UIButton()
    fileprivate let progressView = CameraOverlayProgressView()
    var timer:Timer?
    var blSheet = UIAlertController()
    var deviceLastCount: Int = 0

    //bluetoothCode
    var btService : BLEService?
    var btMotorControl : MotorControl?
    var btDevices = [CBPeripheral]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)!
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        tabController?.delegate = self
        
        setupCamera()
        setupScene()

        if bt == nil {
            bt = BLEDiscovery(onDeviceFound: onDeviceFound, onDeviceConnected: onDeviceConnected, services: [MotorControl.BLEServiceUUID])
        } else {
            btService = BLEService(initWithPeripheral: bt.connectedPeripherals[0], onServiceConnected: onServiceConnected, bleService: MotorControl.BLEServiceUUID, bleCharacteristic: [MotorControl.BLECharacteristicUUID, MotorControl.BLECharacteristicResponseUUID])
            btService?.startDiscoveringServices()
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIApplication.shared.setStatusBarHidden(true, with: .none)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
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
    }

    fileprivate func setupScene() {
        
//        backButton = backButton?.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
//        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backButton, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(closeCamera))
        
        
        backButton.setBackgroundImage(UIImage(named: "camera_back_button"), for: UIControlState())
        backButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        view.addSubview(backButton)
        
        backButton.anchorInCorner(.topLeft, xPad: 15, yPad: 26, width: 20, height: 20)
        
        progressView.progress = 0
        view.addSubview(progressView)
        
        progressView.autoPinEdge(.top, to: .top, of: view, withOffset: 31)
        progressView.autoMatch(.width, to: .width, of: view, withOffset: -80)
        progressView.autoAlignAxis(.vertical, toSameAxisOf: view)
        
        
        manualButton.addTarget(self, action: #selector(manualClicked), for: .touchUpInside)
        motorButton.addTarget(self, action: #selector(motorClicked), for: .touchUpInside)
        
        view.addSubview(manualButton)
        view.addSubview(motorButton)
        
        if let buttonSize = UIImage(named: "manualButton_on")?.size {
            
            let padding = (view.width - (buttonSize.width * 2)) / 3
            
            view.groupInCenter(group: .horizontal, views: [manualButton, motorButton], padding: padding, width: buttonSize.width, height: buttonSize.height)
        }
        
        manualLabel.text = "MANUAL MODE"
        manualLabel.font = UIFont(name: "Avenir-Heavy", size: 17)
        view.addSubview(manualLabel)
        
        motorLabel.text = "MOTOR MODE"
        motorLabel.font = UIFont(name: "Avenir-Heavy", size: 17)
        view.addSubview(motorLabel)
        
        Defaults[.SessionMotor] ? isMotorMode(true) : isMotorMode(false)
        
        manualLabel.align(.underCentered, relativeTo: manualButton, padding: 10, width: calcTextWidth(manualLabel.text!, withFont: manualLabel.font), height: 23)
        motorLabel.align(.underCentered, relativeTo: motorButton, padding: 10, width: calcTextWidth(motorLabel.text!, withFont: motorLabel.font), height: 23)
        
//        cameraButton.setBackgroundImage(UIImage(named: "camera_icn"), forState: .Normal)
//        let size = UIImage(named:"camera_icn")!.size
//        cameraButton.addTarget(self, action: #selector(record), forControlEvents: .TouchUpInside)
//        view.addSubview(cameraButton)
//        cameraButton.anchorToEdge(.Bottom, padding: 20, width: size.width, height: size.height)
    }

    func closeCamera() {
        navigationController?.popViewController(animated: false)
    }
    
    func record() {
        if Defaults[.SessionMotor] {
//            if deviceList.count == 0 {
//                let confirmAlert = UIAlertController(title: "Error!", message: "Motor mode requires Bluetooth turned ON and paired to any DSCVR Orbit Motor.", preferredStyle: .alert)
//                confirmAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
//                self.present(confirmAlert, animated: true, completion: nil)
//            } else {
//                for dev in deviceList {
//                    if getCBPeripheralState(dev.state) == "Connected" {
//                        navigationController?.pushViewController(CameraViewController(), animated: false)
//                        navigationController?.viewControllers.remove(at: 1)
//                        return
//                    }
//                }
//                let confirmAlert = UIAlertController(title: "Error!", message: "Motor mode requires Bluetooth turned ON and paired to any DSCVR Orbit Motor.", preferredStyle: .alert)
//                confirmAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
//                self.present(confirmAlert, animated: true, completion: nil)
//            }
            if btMotorControl == nil {
                let confirmAlert = UIAlertController(title: "Error!", message: "Motor mode requires Bluetooth turned ON and paired to any DSCVR Orbit Motor.", preferredStyle: .alert)
                confirmAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(confirmAlert, animated: true, completion: nil)
            }
            print("wohooo")
        } else {
            navigationController?.pushViewController(CameraViewController(), animated: false)
            let cvc = navigationController?.viewControllers[2] as! CameraViewController
            cvc.motorControl = btMotorControl
            navigationController?.viewControllers.remove(at: 1)
        }
    }

    func isMotorMode(_ state:Bool) {
        if state {
            manualButton.setBackgroundImage(UIImage(named: "manualButton_off"), for: UIControlState())
            motorButton.setBackgroundImage(UIImage(named: "motorButton_on"), for: UIControlState())
            
            manualLabel.textColor = UIColor(0x979797)
            motorLabel.textColor = UIColor(0xFF5E00)
        } else {
            manualButton.setBackgroundImage(UIImage(named: "manualButton_on"), for: UIControlState())
            motorButton.setBackgroundImage(UIImage(named: "motorButton_off"), for: UIControlState())
            
            manualLabel.textColor = UIColor(0xFF5E00)
            motorLabel.textColor = UIColor(0x979797)
        }
    }
    
    func manualClicked() {
        isMotorMode(false)
        Defaults[.SessionMotor] = false
        Defaults[.SessionUseMultiRing] = false
        
        timer?.invalidate()
    }
    
    func motorClicked() {
        
        isMotorMode(true)
        Defaults[.SessionMotor] = true
        Defaults[.SessionUseMultiRing] = true
        
    }
    
    fileprivate func setupCamera() {
        authorizeCamera()
        
        session.sessionPreset = AVCaptureSessionPreset1280x720
        
        videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!) else {
            return
        }
        
        session.beginConfiguration()
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        }
        
        let videoDeviceOutput = AVCaptureVideoDataOutput()
        // TODO. 
        //videoDeviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
        videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
        //videoDeviceOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if session.canAddOutput(videoDeviceOutput) {
            session.addOutput(videoDeviceOutput)
        }
        
        let conn = videoDeviceOutput.connection(withMediaType: AVMediaTypeVideo)!
        conn.videoOrientation = AVCaptureVideoOrientation.portrait
        
        session.commitConfiguration()
        
        try! videoDevice?.lockForConfiguration()
        
        
        var bestFormat: AVCaptureDeviceFormat?
        
        var maxFps: Double = 0
        
        for format in videoDevice!.formats.map({ $0 as! AVCaptureDeviceFormat }) {
            var ranges = format.videoSupportedFrameRateRanges as! [AVFrameRateRange]
            let frameRates = ranges[0]
            if frameRates.maxFrameRate >= maxFps && frameRates.maxFrameRate <= 30 {
                maxFps = frameRates.maxFrameRate
                bestFormat = format
                
            }
        }
        
        if videoDevice!.activeFormat.isVideoHDRSupported {
            videoDevice!.automaticallyAdjustsVideoHDREnabled = false
            videoDevice!.isVideoHDREnabled = false
        }

        videoDevice!.exposureMode = .continuousAutoExposure
        videoDevice!.whiteBalanceMode = .continuousAutoWhiteBalance
        
        AVCaptureVideoStabilizationMode.standard
        
        videoDevice!.activeVideoMinFrameDuration = CMTimeMake(1, 30)
        videoDevice!.activeVideoMaxFrameDuration = CMTimeMake(1, 30)
        
        videoDevice!.unlockForConfiguration()
        
        session.startRunning()
    }
    
    fileprivate func authorizeCamera() {
        var alreadyFailed = false
        let failAlert = {
            Async.main { [weak self] in
                if alreadyFailed {
                    return
                } else {
                    alreadyFailed = true
                }
                
                let alert = UIAlertController(title: "No access to camera", message: "Please enable permission to use the camera and photos.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Enable", style: .default, handler: { _ in
                    UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
                }))
                self?.present(alert, animated: true, completion: nil)
            }
        }
        
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { granted in
            if !granted {
                failAlert()
            }
        })
        
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .notDetermined, .restricted, .denied: failAlert()
            default: ()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let videoDevice = self.videoDevice {
            try! videoDevice.lockForConfiguration()
            videoDevice.focusMode = .continuousAutoFocus
            videoDevice.exposureMode = .continuousAutoExposure
            videoDevice.whiteBalanceMode = .continuousAutoWhiteBalance
            videoDevice.unlockForConfiguration()
        }
        
        session.stopRunning()
        videoDevice = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
private class CameraOverlayProgressView: UIView {
    
    var progress: Float = 0 {
        didSet {
            layoutSubviews()
        }
    }
    var isActive = false {
        didSet {
            foregroundLine.backgroundColor = isActive ? UIColor(hex:0xFF5E00).cgColor : UIColor.white.cgColor
            trackingPoint.backgroundColor = isActive ? UIColor(hex:0xFF5E00).cgColor : UIColor.white.cgColor
        }
    }
    
    fileprivate let firstBackgroundLine = CALayer()
    fileprivate let endPoint = CALayer()
    fileprivate let foregroundLine = CALayer()
    fileprivate let trackingPoint = CALayer()
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        firstBackgroundLine.backgroundColor = UIColor.white.cgColor
        layer.addSublayer(firstBackgroundLine)
        
        endPoint.backgroundColor = UIColor.white.cgColor
        endPoint.cornerRadius = 3.5
        layer.addSublayer(endPoint)
        
        foregroundLine.cornerRadius = 1
        layer.addSublayer(foregroundLine)
        
        trackingPoint.cornerRadius = 7
        layer.addSublayer(trackingPoint)
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = bounds.width - 12
        let originX = bounds.origin.x + 6
        let originY = bounds.origin.y + 6
        
        firstBackgroundLine.frame = CGRect(x: originX, y: originY - 0.6, width: width, height: 1.2)
        endPoint.frame = CGRect(x: width + 3.5, y: originY - 3.5, width: 7, height: 7)
        foregroundLine.frame = CGRect(x: originX, y: originY - 1, width: width * CGFloat(progress), height: 2)
        trackingPoint.frame = CGRect(x: originX + width * CGFloat(progress) - 6, y: originY - 6, width: 12, height: 12)
    }
}

extension CameraOverlayVC: TabControllerDelegate {
    
    func onTapCameraButton() {
        record()
    }
}


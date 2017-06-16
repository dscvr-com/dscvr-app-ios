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
let remoteManualNotificationKey = "meyer.remoteManual"
let remoteMotorNotificationKey = "meyer.remoteMotor"

class CameraOverlayVC: UIViewController {
    
    fileprivate let session = AVCaptureSession()
    fileprivate var videoDevice : AVCaptureDevice?
    fileprivate let manualButton = UIButton()
    fileprivate let motorButton = UIButton()
    fileprivate let motorLabel = UILabel()
    fileprivate let manualLabel = UILabel()
    fileprivate var backButton = UIButton()
    var blSheet = UIAlertController()
    var deviceLastCount: Int = 0
    let connectionstatus = UILabel()
    var verticalTimer = Timer()
    var motorButtonClicked = false

    //bluetoothCode
    var btService : BLEService?
    var btMotorControl : MotorControl?
    var btDevices = [CBPeripheral]()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.remoteManual), name: NSNotification.Name(rawValue: remoteManualNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.remoteMotor), name: NSNotification.Name(rawValue: remoteMotorNotificationKey), object: nil)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)!
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        tabController?.delegate = self

        connectionstatus.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 20)
        connectionstatus.text = "Looking for Orbit 360 Motor..."
        connectionstatus.textAlignment = .center
        connectionstatus.font = connectionstatus.font.withSize(12)
        connectionstatus.textColor = UIColor.white
        connectionstatus.backgroundColor = UIColor.black
        view.addSubview(connectionstatus)

        setupCamera()
        setupScene()

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

    func remoteManual() {
        NotificationCenter.default.removeObserver(self)
        manualClicked()
        onTapCameraButton()
    }

    func remoteMotor() {
        NotificationCenter.default.removeObserver(self)
        motorClicked()
        onTapCameraButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        UIApplication.shared.setStatusBarHidden(true, with: .none)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
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
        connectionstatus.text = "Orbit 360 Motor connected"
    }

    fileprivate func setupScene() {
        backButton.setBackgroundImage(UIImage(named: "camera_back_button"), for: UIControlState())
        backButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        view.addSubview(backButton)
        
        backButton.anchorInCorner(.topLeft, xPad: 15, yPad: 26, width: 20, height: 20)
        
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
            }

    func closeCamera() {
        navigationController?.popViewController(animated: false)
        verticalTimer.invalidate()
    }

    func record() {
        if Defaults[.SessionMotor] {
            if motorButtonClicked {
                if btMotorControl == nil {
                    self.tabController!.cameraButton.isHidden = false
                    let confirmAlert = UIAlertController(title: "Error!", message: "Motor mode requires Bluetooth turned ON and paired to any DSCVR Orbit Motor.", preferredStyle: .alert)
                    confirmAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(confirmAlert, animated: true, completion: nil)
                    motorButton.isUserInteractionEnabled = true
                    manualButton.isUserInteractionEnabled = true
                    backButton.isHidden = false
                } else {
                    // Disabled code to re-calib the motor.
                    //let stepsToFront = Float(MotorControl.motorStepsY) * (135 / 360)
                    //btMotorControl?.moveY(Int32(stepsToFront), speed: 1000)
                    //verticalTimer = Timer.scheduledTimer(timeInterval: TimeInterval(Float(stepsToFront) / Float(1000)), target: self, selector: #selector(moveToVertical), userInfo: nil, repeats: false)

                    goToCameraViewContoller();
                }
            } else {
                motorButtonClicked = true
                backButton.isHidden = false
                tabController!.cameraButton.isHidden = false
                manualButton.setBackgroundImage(UIImage(named: "one_ring_active_icn"), for: UIControlState())
                motorButton.setBackgroundImage(UIImage(named: "motorButton_off"), for: UIControlState())
                motorButton.isUserInteractionEnabled = true
                manualButton.isUserInteractionEnabled = true
                motorLabel.textColor = UIColor(0x979797)
                motorLabel.text = "3-RING MODE"
                manualLabel.textColor = UIColor(0xFF5E00)
                manualLabel.text = "1-RING MODE"


            }
        } else {
            navigationController?.pushViewController(CameraViewController(), animated: false)
            navigationController?.viewControllers.remove(at: 1)
        }
    }

    func moveToVertical() {
        let stepsToVertical = Float(MotorControl.motorStepsY) * (45 / 360)
        self.btMotorControl?.moveY(Int32(-stepsToVertical), speed: 1000)
        goToCameraViewContoller();
    }
    
    func goToCameraViewContoller() {
        self.navigationController?.pushViewController(CameraViewController(), animated: false)
        let cvc = self.navigationController?.viewControllers[2] as! CameraViewController
        cvc.motorControl = self.btMotorControl
        cvc.motionManager = cvc.motorControl
        self.navigationController?.viewControllers.remove(at: 1)
    }

    func isMotorMode(_ state:Bool) {
        if state {
            if motorButtonClicked {
                manualButton.setBackgroundImage(UIImage(named: "one_ring_inactive_icnwhite"), for: UIControlState())
                motorButton.setBackgroundImage(UIImage(named: "motorButton_on"), for: UIControlState())
            } else {
                manualButton.setBackgroundImage(UIImage(named: "manualButton_off"), for: UIControlState())
                motorButton.setBackgroundImage(UIImage(named: "motor_active"), for: UIControlState())
            }

            manualLabel.textColor = UIColor(0x979797)
            motorLabel.textColor = UIColor(0xFF5E00)
        } else {
            if motorButtonClicked {
                manualButton.setBackgroundImage(UIImage(named: "one_ring_active_icn"), for: UIControlState())
                motorButton.setBackgroundImage(UIImage(named: "motorButton_off"), for: UIControlState())
            } else {
                manualButton.setBackgroundImage(UIImage(named: "manualButton_on"), for: UIControlState())
                motorButton.setBackgroundImage(UIImage(named: "motor_inactive_white"), for: UIControlState())
            }

            manualLabel.textColor = UIColor(0xFF5E00)
            motorLabel.textColor = UIColor(0x979797)
        }
    }
    
    func manualClicked() {
        isMotorMode(false)
        if motorButtonClicked {
            Defaults[.SessionMotor] = true
            Defaults[.SessionUseMultiRing] = false
        } else {
            Defaults[.SessionMotor] = false
            Defaults[.SessionUseMultiRing] = false
        }
    }
    
    func motorClicked() {
        isMotorMode(true)
        if motorButtonClicked {
            Defaults[.SessionMotor] = true
            Defaults[.SessionUseMultiRing] = true
        } else {
            Defaults[.SessionMotor] = true
            Defaults[.SessionUseMultiRing] = false
        }
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
        videoDeviceOutput.alwaysDiscardsLateVideoFrames = true

        if session.canAddOutput(videoDeviceOutput) {
            session.addOutput(videoDeviceOutput)
        }
        
        let conn = videoDeviceOutput.connection(withMediaType: AVMediaTypeVideo)!
        conn.videoOrientation = AVCaptureVideoOrientation.portrait
        
        session.commitConfiguration()
        
        try! videoDevice?.lockForConfiguration()
        
        if videoDevice!.activeFormat.isVideoHDRSupported {
            videoDevice!.automaticallyAdjustsVideoHDREnabled = false
            videoDevice!.isVideoHDREnabled = false
        }

        videoDevice!.exposureMode = .continuousAutoExposure
        videoDevice!.whiteBalanceMode = .continuousAutoWhiteBalance

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

extension CameraOverlayVC: TabControllerDelegate {
    
    func onTapCameraButton() {
        tabController!.cameraButton.isHidden = true
        backButton.isHidden = true
        motorButton.isUserInteractionEnabled = false
        manualButton.isUserInteractionEnabled = false
        record()
    }
}


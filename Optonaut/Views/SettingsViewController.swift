//
//  SettingsViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 5/17/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class SettingsViewController: UIViewController {
    
    var thisView = UIView()
    var isSettingsViewOpen:Bool = false
    private var motorButton = SettingsButton()
    private var manualButton = SettingsButton()
    private var oneRingButton = SettingsButton()
    private var threeRingButton = SettingsButton()
    private var vrButton = SettingsButton()
    private var pullButton = SettingsButton()
    private var gyroButton = SettingsButton()
    private var littlePlanet = SettingsButton()
    
    let labelRing1 = UILabel()
    let labelRing3 = UILabel()
    let labelManual = UILabel()
    let labelMotor = UILabel()
    let labelGyro = UILabel()
    let planet = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.settingsView()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func settingsView() {
        
        thisView.frame = CGRectMake(0, -(view.frame.height), view.frame.width, view.frame.height)
        thisView.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(thisView)
        
        let titleSettings = UILabel()
        titleSettings.text = "Settings"
        titleSettings.textAlignment = .Center
        titleSettings.textColor = UIColor.blackColor()
        titleSettings.font = .displayOfSize(25, withType: .Light)
        thisView.addSubview(titleSettings)
        titleSettings.anchorToEdge(.Top, padding: 30, width: calcTextWidth(titleSettings.text!, withFont: .displayOfSize(25, withType: .Light)), height: 30)
        
        let vrText = UILabel()
        vrText.frame = CGRect(x: 38,y: titleSettings.frame.origin.y + 30+50,width: calcTextWidth("CAPTURE IAM360 IMAGES IN", withFont: .displayOfSize(15, withType: .Semibold)),height: 25)
        vrText.text = "CAPTURE IAM360 IMAGES IN"
        vrText.textAlignment = .Center
        vrText.textColor = UIColor.blackColor()
        vrText.font = .displayOfSize(15, withType: .Semibold)
        thisView.addSubview(vrText)
        
        
        vrButton.icon = UIImage(named: "vr_button")!
        thisView.addSubview(vrButton)
        vrButton.addTarget(self, action: #selector(self.inVrMode), forControlEvents:.TouchUpInside)
        vrButton.align(.ToTheRightCentered, relativeTo: vrText, padding: 8, width: vrButton.icon.size.width, height: vrButton.icon.size.width)
        
        let labelCamera = UILabel()
        labelCamera.textAlignment = NSTextAlignment.Center
        labelCamera.text = "Feed Display"
        labelCamera.font = .displayOfSize(15, withType: .Semibold)
        labelCamera.textColor = UIColor.blackColor()
        thisView.addSubview(labelCamera)
        labelCamera.align(.UnderCentered, relativeTo: vrText, padding: 27, width: calcTextWidth("Feed Display", withFont: .displayOfSize(15, withType: .Semibold)), height: 25)
        
        let dividerOneHeight = (UIImage(named: "gyro_active_icn")!.size.height * 2) + 12
        
        let dividerOne = UILabel()
        dividerOne.backgroundColor = UIColor(hex:0x595959)
        thisView.addSubview(dividerOne)
        dividerOne.align(.UnderCentered, relativeTo: labelCamera, padding: 10, width:2, height: dividerOneHeight)
        
        gyroButton.addTarget(self, action: #selector(self.gyroButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(gyroButton)
        gyroButton.align(.ToTheLeftMatchingTop, relativeTo: dividerOne, padding: 38, width: gyroButton.icon.size.width, height: gyroButton.icon.size.height)
        
        
        labelGyro.textAlignment = NSTextAlignment.Center
        labelGyro.textColor = UIColor.blackColor()
        labelGyro.text = "GYRO"
        labelGyro.font = .displayOfSize(20, withType: .Semibold)
        thisView.addSubview(labelGyro)
        labelGyro.align(.ToTheRightCentered, relativeTo: gyroButton, padding: 50, width: calcTextWidth("GYRO", withFont: .displayOfSize(20, withType: .Semibold)), height: 25)
        
        littlePlanet.addTarget(self, action: #selector(self.littlePlanetButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(littlePlanet)
        littlePlanet.align(.UnderCentered, relativeTo: gyroButton, padding: 12, width: littlePlanet.icon.size.width, height: littlePlanet.icon.size.height)
        
        planet.textAlignment = NSTextAlignment.Center
        planet.textColor = UIColor.blackColor()
        planet.text = "LITTLE PLANET"
        planet.font = .displayOfSize(20, withType: .Semibold)
        thisView.addSubview(planet)
        planet.align(.ToTheRightCentered, relativeTo: littlePlanet, padding: 50, width: calcTextWidth("LITTLE PLANET", withFont: .displayOfSize(20, withType: .Semibold)), height: 25)
        
        let labelMode = UILabel()
        labelMode.textAlignment = NSTextAlignment.Center
        labelMode.textColor = UIColor.blackColor()
        labelMode.text = "Mode"
        labelMode.font = .displayOfSize(15, withType: .Semibold)
        thisView.addSubview(labelMode)
        labelMode.align(.UnderCentered, relativeTo: dividerOne, padding: 10, width: calcTextWidth("Mode", withFont: .displayOfSize(15, withType: .Semibold)), height: 25)
        
        let dividerTwo = UILabel()
        dividerTwo.backgroundColor = UIColor(hex:0x595959)
        thisView.addSubview(dividerTwo)
        dividerTwo.align(.UnderCentered, relativeTo: labelMode, padding: 10, width:2, height: dividerOneHeight)
        
        oneRingButton.addTarget(self, action: #selector(self.oneRingButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(oneRingButton)
        oneRingButton.align(.ToTheLeftMatchingTop, relativeTo: dividerTwo, padding: 38, width: oneRingButton.icon.size.width, height: oneRingButton.icon.size.height)
        
        labelRing1.textAlignment = NSTextAlignment.Center
        labelRing1.text = "ONE RING"
        labelRing1.font = .displayOfSize(20, withType: .Semibold)
        thisView.addSubview(labelRing1)
        labelRing1.align(.ToTheRightCentered, relativeTo: oneRingButton, padding: 50, width: calcTextWidth("ONE RING", withFont: .displayOfSize(20, withType: .Semibold)), height: 25)
        
        threeRingButton.align(.UnderCentered, relativeTo: oneRingButton, padding: 12, width: threeRingButton.icon.size.width, height: threeRingButton.icon.size.height)
        threeRingButton.addTarget(self, action: #selector(self.threeRingButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(threeRingButton)
        
        labelRing3.textAlignment = NSTextAlignment.Center
        labelRing3.text = "THREE RING"
        labelRing3.font = .displayOfSize(20, withType: .Semibold)
        labelRing3.align(.ToTheRightCentered, relativeTo: threeRingButton, padding: 50, width: calcTextWidth("THREE RING", withFont: .displayOfSize(20, withType: .Semibold)), height: 25)
        thisView.addSubview(labelRing3)
        
        let labelCapture = UILabel()
        labelCapture.textAlignment = NSTextAlignment.Center
        labelCapture.text = "Capture Type"
        labelCapture.textColor = UIColor.blackColor()
        labelCapture.font = .displayOfSize(15, withType: .Semibold)
        thisView.addSubview(labelCapture)
        labelCapture.align(.UnderCentered, relativeTo: dividerTwo, padding: 10, width: calcTextWidth("Capture Type", withFont: .displayOfSize(15, withType: .Semibold)), height: 25)
        
        let dividerThree = UILabel()
        dividerThree.backgroundColor = UIColor(hex:0x595959)
        thisView.addSubview(dividerThree)
        dividerThree.align(.UnderCentered, relativeTo: labelCapture, padding: 10, width:2, height: dividerOneHeight)
        
        manualButton.addTarget(self, action: #selector(self.manualButtonTouched), forControlEvents:.TouchUpInside)
        thisView.addSubview(manualButton)
        manualButton.align(.ToTheLeftMatchingTop, relativeTo: dividerThree, padding: 38, width: manualButton.icon.size.width, height: manualButton.icon.size.height)
        
        labelManual.textAlignment = NSTextAlignment.Center
        labelManual.text = "MANUAL"
        labelManual.textColor = UIColor(hex:0xffbc00)
        labelManual.font = .displayOfSize(20, withType: .Semibold)
        thisView.addSubview(labelManual)
        labelManual.align(.ToTheRightCentered, relativeTo: manualButton, padding: 50, width: calcTextWidth("MANUAL", withFont: .displayOfSize(20, withType: .Semibold)), height: 25)
        
        motorButton.addTarget(self, action: #selector(self.motorButtonTouched), forControlEvents:.TouchUpInside)
        motorButton.align(.UnderCentered, relativeTo: manualButton, padding: 12, width: motorButton.icon.size.width, height: motorButton.icon.size.height)
        thisView.addSubview(motorButton)
        
        labelMotor.textAlignment = NSTextAlignment.Center
        labelMotor.text = "MOTOR"
        labelMotor.textColor = UIColor(hex:0xffbc00)
        labelMotor.font = .displayOfSize(20, withType: .Semibold)
        labelMotor.align(.ToTheRightCentered, relativeTo: motorButton, padding: 50, width: calcTextWidth("MOTOR", withFont: .displayOfSize(20, withType: .Semibold)), height: 25)
        thisView.addSubview(labelMotor)
        
        self.activeRingButtons(Defaults[.SessionUseMultiRing])
        self.activeModeButtons(Defaults[.SessionMotor])
        self.activeVrMode()
        self.activeDisplayButtons(Defaults[.SessionGyro])
        
    }
    func gyroButtonTouched() {
        Defaults[.SessionGyro] = true
        self.activeDisplayButtons(true)
    }
    func littlePlanetButtonTouched() {
        Defaults[.SessionGyro] = false
        self.activeDisplayButtons(false)
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
    func inVrMode() {
        if Defaults[.SessionVRMode] {
            vrButton.icon = UIImage(named: "vr_inactive_btn")!
            Defaults[.SessionVRMode] = false
        } else {
            vrButton.icon = UIImage(named: "vr_button")!
            Defaults[.SessionVRMode] = true
        }
    }
    func activeVrMode() {
        if Defaults[.SessionVRMode] {
            vrButton.icon = UIImage(named: "vr_inactive_btn")!
        } else {
            vrButton.icon = UIImage(named: "vr_button")!
        }
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
    func activeDisplayButtons(isGyro:Bool) {
        
        if isGyro {
            gyroButton.icon = UIImage(named: "gyro_active_icn")!
            littlePlanet.icon = UIImage(named: "littlePlanet_inactive_icn")!
            
            labelGyro.textColor = UIColor(hex:0xffbc00)
            planet.textColor = UIColor.grayColor()
            
        } else {
            gyroButton.icon = UIImage(named: "gyro_inactive_icn")!
            littlePlanet.icon = UIImage(named: "littlePlanet_active_icn")!
            
            labelGyro.textColor = UIColor.grayColor()
            planet.textColor = UIColor(hex:0xffbc00)
        }
    }

}

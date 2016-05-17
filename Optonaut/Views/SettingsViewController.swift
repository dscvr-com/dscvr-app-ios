//
//  SettingsViewController.swift
//  Iam360
//
//  Created by robert john alkuino on 5/17/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    var thisView = UIView()
    var isSettingsViewOpen:Bool = false
//    private var motorButton = SettingsButton()
//    private var manualButton = SettingsButton()
//    private var oneRingButton = SettingsButton()
//    private var threeRingButton = SettingsButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    func settingsView() {
//        thisView.frame = CGRectMake(0, -(view.frame.height), view.frame.width, view.frame.height)
//        thisView.backgroundColor = UIColor.blackColor()
//        self.view.addSubview(thisView)
//        
//        let image: UIImage = UIImage(named: "logo_big")!
//        var bgImage: UIImageView?
//        bgImage = UIImageView(image: image)
//        thisView.addSubview(bgImage!)
//        bgImage!.anchorToEdge(.Top, padding: 60, width: view.frame.size.width * 0.5, height: view.frame.size.height * 0.13)
//        
//        let labelHeightMultiplier:CGFloat = 0.3 * bgImage!.frame.size.height
//        let buttonsHeightMultiplier:CGFloat = 0.9 * bgImage!.frame.size.height
//        
//        let labelCamera = UILabel()
//        labelCamera.textAlignment = NSTextAlignment.Center
//        labelCamera.text = "Camera Settings"
//        labelCamera.textColor = UIColor.whiteColor()
//        thisView.addSubview(labelCamera)
//        labelCamera.align(.UnderCentered, relativeTo: bgImage!, padding: 15, width: 200, height: labelHeightMultiplier)
//        
//        let labelMode = UILabel()
//        labelMode.textAlignment = NSTextAlignment.Center
//        labelMode.textColor = UIColor.whiteColor()
//        labelMode.text = "Mode"
//        thisView.addSubview(labelMode)
//        labelMode.align(.UnderCentered, relativeTo: labelCamera, padding: 15, width: 100, height: labelHeightMultiplier)
//        
//        oneRingButton.frame = CGRect(x: self.view.frame.width*0.25 , y: labelMode.frame.origin.y + 40 , width: buttonsHeightMultiplier, height: buttonsHeightMultiplier)
//        oneRingButton.addTarget(self, action: #selector(TabViewController.oneRingButtonTouched), forControlEvents:.TouchUpInside)
//        thisView.addSubview(oneRingButton)
//        
//        labelRing1.textAlignment = NSTextAlignment.Center
//        labelRing1.text = "One Ring"
//        labelRing1.align(.UnderCentered, relativeTo: oneRingButton, padding: 5, width: 200, height: labelHeightMultiplier)
//        thisView.addSubview(labelRing1)
//        
//        threeRingButton.align(.ToTheRightMatchingTop, relativeTo: oneRingButton, padding: 40, width: buttonsHeightMultiplier, height: buttonsHeightMultiplier)
//        threeRingButton.addTarget(self, action: #selector(TabViewController.threeRingButtonTouched), forControlEvents:.TouchUpInside)
//        thisView.addSubview(threeRingButton)
//        
//        labelRing3.textAlignment = NSTextAlignment.Center
//        labelRing3.text = "Three Ring"
//        labelRing3.align(.UnderCentered, relativeTo: threeRingButton, padding: 5, width: 200, height: labelHeightMultiplier)
//        thisView.addSubview(labelRing3)
//        
//        let line = UILabel()
//        line.frame = CGRect(x: 15 , y: labelRing3.frame.origin.y + labelRing3.frame.height + 50 , width: self.view.frame.width-15, height: 1)
//        line.backgroundColor = UIColor.grayColor()
//        thisView.addSubview(line)
//        
//        let labelCapture = UILabel()
//        labelCapture.textAlignment = NSTextAlignment.Center
//        labelCapture.text = "Capture Type"
//        labelCapture.textColor = UIColor.whiteColor()
//        thisView.addSubview(labelCapture)
//        labelCapture.align(.UnderCentered, relativeTo: line, padding: 15, width: 200, height: labelHeightMultiplier)
//        
//        manualButton.frame = CGRect(x: self.view.frame.width*0.25 , y: labelCapture.frame.origin.y + 40 , width: buttonsHeightMultiplier, height: buttonsHeightMultiplier)
//        manualButton.addTarget(self, action: #selector(TabViewController.manualButtonTouched), forControlEvents:.TouchUpInside)
//        thisView.addSubview(manualButton)
//        
//        motorButton.align(.ToTheRightMatchingTop, relativeTo: manualButton, padding: 40, width: buttonsHeightMultiplier, height: buttonsHeightMultiplier)
//        motorButton.addTarget(self, action: #selector(TabViewController.motorButtonTouched), forControlEvents:.TouchUpInside)
//        thisView.addSubview(motorButton)
//        
//        labelManual.textAlignment = NSTextAlignment.Center
//        labelManual.text = "Manual"
//        labelManual.textColor = UIColor(hex:0xffbc00)
//        labelManual.align(.UnderCentered, relativeTo: manualButton, padding: 5, width: 200, height:labelHeightMultiplier)
//        thisView.addSubview(labelManual)
//        
//        labelMotor.textAlignment = NSTextAlignment.Center
//        labelMotor.text = "Motor"
//        labelMotor.textColor = UIColor(hex:0xffbc00)
//        labelMotor.align(.UnderCentered, relativeTo: motorButton, padding: 5, width: 200, height:labelHeightMultiplier)
//        thisView.addSubview(labelMotor)
//        
//        pullButton.icon = UIImage(named:"arrow_pull")!
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TabViewController.handlePan(_:)))
//        pullButton.addGestureRecognizer(panGestureRecognizer)
//        thisView.addGestureRecognizer(panGestureRecognizer)
//        
//        //pullButton.addTarget(self, action: #selector(FeedNavViewController.pullButtonTap), forControlEvents:.TouchUpInside)
//        thisView.addSubview(pullButton)
//        pullButton.anchorToEdge(.Bottom, padding: 5, width: 20, height: 15)
//        
//        self.activeRingButtons(Defaults[.SessionUseMultiRing])
//        self.activeModeButtons(Defaults[.SessionMotor])
//    }
//    
//    
//    func pullButtonTap() {
//        UIView.animateWithDuration(1.0, delay: 1.2, options: .CurveEaseOut, animations: {
//            if var settingsViewCount:CGFloat = self.thisView.frame.origin.y {
//                settingsViewCount -= self.view.frame.origin.y
//                self.thisView.frame = CGRectMake(0, settingsViewCount , self.view.frame.width, self.view.frame.height)
//            }
//            }, completion: { finished in
//                self.isSettingsViewOpen = false
//                
//        })
//    }
//    
//    
//    
//    func motorButtonTouched() {
//        Defaults[.SessionMotor] = true
//        self.activeModeButtons(true)
//    }
//    
//    func manualButtonTouched() {
//        Defaults[.SessionMotor] = false
//        self.activeModeButtons(false)
//    }
//    
//    func oneRingButtonTouched() {
//        Defaults[.SessionUseMultiRing] = false
//        self.activeRingButtons(false)
//    }
//    
//    func threeRingButtonTouched() {
//        Defaults[.SessionUseMultiRing] = true
//        self.activeRingButtons(true)
//    }
//    func activeModeButtons(isMotor:Bool) {
//        if isMotor {
//            motorButton.icon = UIImage(named: "motor_active_icn")!
//            manualButton.icon = UIImage(named: "manual_inactive_icn")!
//            
//            labelManual.textColor = UIColor.grayColor()
//            labelMotor.textColor = UIColor(hex:0xffbc00)
//        } else {
//            motorButton.icon = UIImage(named: "motor_inactive_icn")!
//            manualButton.icon = UIImage(named: "manual_active_icn")!
//            
//            labelManual.textColor = UIColor(hex:0xffbc00)
//            labelMotor.textColor = UIColor.grayColor()
//        }
//    }
//    
//    func activeRingButtons(isMultiRing:Bool) {
//        
//        if isMultiRing {
//            threeRingButton.icon = UIImage(named: "threeRing_active_icn")!
//            oneRingButton.icon = UIImage(named: "oneRing_inactive_icn")!
//            
//            labelRing3.textColor = UIColor(hex:0xffbc00)
//            labelRing1.textColor = UIColor.grayColor()
//            
//        } else {
//            threeRingButton.icon = UIImage(named: "threeRing_inactive_icn")!
//            oneRingButton.icon = UIImage(named: "oneRing_active_icn")!
//            
//            labelRing3.textColor = UIColor.grayColor()
//            labelRing1.textColor = UIColor(hex:0xffbc00)
//        }
//    }

}

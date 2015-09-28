//
//  OnboardingVRViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/27/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import HexColor

class OnboardingVRViewController: UIViewController {
    
    // subviews
    let headlineTextView = UILabel()
    let iconView = UILabel()
    let iconTextView = UILabel()
    let nextButtonView = HatchedButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .Accent
        
        headlineTextView.numberOfLines = 3
        headlineTextView.textAlignment = .Center
        headlineTextView.text = "To view these pictures you will need VR glasses,\r\nsuch as a Google Cardboard"
        headlineTextView.textColor = .whiteColor()
        headlineTextView.font = UIFont.displayOfSize(25, withType: .Thin)
        view.addSubview(headlineTextView)
        
        iconView.textAlignment = .Center
        iconView.text = String.iconWithName(.OnboardingVr)
        iconView.textColor = .whiteColor()
        iconView.font = UIFont.iconOfSize(60)
        view.addSubview(iconView)
        
        let iconTextStr = "You can get your own VR glasses on\r\noptonaut.co/glasses"
        let normalRange = iconTextStr.NSRangeOfString("You can get your own VR glasses on")
        let linkRange = iconTextStr.NSRangeOfString("optonaut.co/glasses")
        let attrString = NSMutableAttributedString(string: iconTextStr)
        attrString.addAttribute(NSFontAttributeName, value: UIFont.displayOfSize(20, withType: .Thin), range: normalRange!)
        attrString.addAttribute(NSFontAttributeName, value: UIFont.displayOfSize(20, withType: .Semibold), range: linkRange!)
        iconTextView.attributedText = attrString
        iconTextView.userInteractionEnabled = true
        iconTextView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "openGlassesPage"))
        iconTextView.numberOfLines = 2
        iconTextView.textAlignment = .Center
        iconTextView.textColor = .whiteColor()
        view.addSubview(iconTextView)
        
        nextButtonView.setTitle("I got VR glasses", forState: .Normal)
        nextButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showProfileOnboarding"))
        view.addSubview(nextButtonView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        
        headlineTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        headlineTextView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 75)
        headlineTextView.autoSetDimension(.Width, toSize: 300)
        
        iconView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        iconView.autoPinEdge(.Bottom, toEdge: .Top, ofView: iconTextView, withOffset: -35)
        
        iconTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        iconTextView.autoPinEdge(.Bottom, toEdge: .Top, ofView: nextButtonView, withOffset: -52)
        iconTextView.autoSetDimension(.Width, toSize: 300)
        
        nextButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        nextButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -42)
        nextButtonView.autoSetDimension(.Height, toSize: 60)
        nextButtonView.autoSetDimension(.Width, toSize: 235)
        
        super.updateViewConstraints()
    }
    
    func showProfileOnboarding() {
        presentViewController(OnboardingProfileViewController(), animated: false, completion: nil)
    }
    
    func openGlassesPage() {
        UIApplication.sharedApplication().openURL(NSURL(string:"http://optonaut.co/glasses")!)
    }
    
}
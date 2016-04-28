//
//  OnboardingInfoViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import Mixpanel

class OnboardingInfoViewController: UIViewController {
    
    // subviews
    let headlineTextView = UILabel()
    let iconView = UILabel()
    let iconTextView = UILabel()
    let nextButtonView = ActionButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .Accent
        
        headlineTextView.numberOfLines = 3
        headlineTextView.textAlignment = .Center
        headlineTextView.text = "Capture and share unique moments in a completely new and immersive way"
        headlineTextView.textColor = .whiteColor()
        headlineTextView.font = UIFont.displayOfSize(25, withType: .Regular)
        view.addSubview(headlineTextView)
        
        iconView.textAlignment = .Center
//        iconView.text = String.iconWithName(.OnboardingInfo)
        iconView.textColor = .whiteColor()
        iconView.font = UIFont.iconOfSize(60)
        view.addSubview(iconView)
        
        iconTextView.numberOfLines = 2
        iconTextView.textAlignment = .Center
        iconTextView.text = "Take your loved ones with you and explore beautiful new places"
        iconTextView.textColor = .whiteColor()
        iconTextView.font = UIFont.displayOfSize(20, withType: .Thin)
        view.addSubview(iconTextView)
        
        nextButtonView.setTitle("Get started", forState: .Normal)
        nextButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(OnboardingInfoViewController.showVROnboarding)))
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
        nextButtonView.autoSetDimension(.Width, toSize: 188)
        
        super.updateViewConstraints()
    }
    
    func showVROnboarding() {
        //view.window?.rootViewController = OnboardingVRViewController()
        view.window?.rootViewController = OnboardingProfileViewController()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.OnboardingInfo")
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.OnboardingInfo")
    }
    
}
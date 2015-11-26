//
//  OnboardingHashtagInfoViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/27/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import Device
import Mixpanel

class OnboardingHashtagInfoViewController: UIViewController {
    
    // subviews
    let headlineTextView = UILabel()
    let iconView = UILabel()
    let iconTextView = UILabel()
    let nextButtonView = ActionButton()
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .Accent
        
        headlineTextView.numberOfLines = 1
        headlineTextView.textAlignment = .Center
        headlineTextView.text = "Show us what you like"
        headlineTextView.textColor = .whiteColor()
        headlineTextView.font = UIFont.displayOfSize(25, withType: .Thin)
        view.addSubview(headlineTextView)
        
        iconView.textAlignment = .Center
        iconView.text = String.iconWithName(.Heart)
        iconView.textColor = .whiteColor()
        iconView.font = UIFont.iconOfSize(90)
        view.addSubview(iconView)
        
        iconTextView.text = "We want to show you exactly that kind\r\nof pictures you’re interested in.\r\n\r\nLet’s set up your personalized feed."
        iconTextView.font = UIFont.displayOfSize(view.frame.width <= 320 ? 18 : 20, withType: .Thin)
        iconTextView.numberOfLines = 4
        iconTextView.textAlignment = .Center
        iconTextView.textColor = .whiteColor()
        view.addSubview(iconTextView)
        
        nextButtonView.setTitle("Prepare feed", forState: .Normal)
        nextButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showHashtagSelectOnboarding"))
        view.addSubview(nextButtonView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        
        headlineTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        headlineTextView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 75)
        headlineTextView.autoSetDimension(.Width, toSize: 300)
        
        iconView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        iconView.autoPinEdge(.Bottom, toEdge: .Top, ofView: iconTextView, withOffset: -65)
        
        iconTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        iconTextView.autoPinEdge(.Bottom, toEdge: .Top, ofView: nextButtonView, withOffset: -52)
        iconTextView.autoSetDimension(.Width, toSize: 320)
        
        nextButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        nextButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -42)
        nextButtonView.autoSetDimension(.Height, toSize: 60)
        nextButtonView.autoSetDimension(.Width, toSize: 235)
        
        super.updateViewConstraints()
    }
    
    func showHashtagSelectOnboarding() {
        view.window?.rootViewController = OnboardingHashtagSelectViewController()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.OnboardingHashtagInfo")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.OnboardingHashtagInfo")
    }
    
}
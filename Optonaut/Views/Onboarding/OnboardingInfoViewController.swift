//
//  OnboardingInfoViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import HexColor

class OnboardingInfoViewController: UIViewController {
    
    // subviews
    let logoView = UILabel()
    let descriptionTextView = UILabel()
    let plusView = UILabel()
    let glassesImageView = UIImageView()
    let glassesTextView = UILabel()
    let nextButtonView = HatchedButton()
    let dotProgressView = DotProgressView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
        logoView.font = UIFont.icomoonOfSize(90)
        logoView.text = String.icomoonWithName(.LogoText)
        logoView.textColor = UIColor.Accent
        view.addSubview(logoView)
        
        descriptionTextView.numberOfLines = 0
        descriptionTextView.textAlignment = .Center
        descriptionTextView.text = "Optonaut lets you capture and share unique moments in a completely new and immersive way."
        descriptionTextView.textColor = UIColor(0x333333)
        descriptionTextView.font = UIFont.robotoOfSize(16, withType: .Regular)
        view.addSubview(descriptionTextView)
        
        plusView.text = "+"
        plusView.textColor = UIColor.Accent
        plusView.font = UIFont.robotoOfSize(30, withType: .Medium)
        view.addSubview(plusView)
        
        glassesImageView.image = UIImage(named: "cardboard")
        view.addSubview(glassesImageView)
        
        glassesTextView.numberOfLines = 0
        glassesTextView.textAlignment = .Center
        glassesTextView.text = "For this experience, you need a Google Cardboard. If you don‘t have one yet, you can purchase it here."
        glassesTextView.textColor = UIColor(0x333333)
        glassesTextView.font = UIFont.robotoOfSize(16, withType: .Regular)
        view.addSubview(glassesTextView)
        
        nextButtonView.setTitle("GET STARTED", forState: .Normal)
        nextButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfileOnboarding"))
        view.addSubview(nextButtonView)
        
        dotProgressView.numberOfDots = 3
        dotProgressView.activeIndex = 0
        view.addSubview(dotProgressView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        
        let contentHeight: CGFloat = 400
        let statusBarOffset: CGFloat = 20
        let buttonOffset: CGFloat = 106
        let topOffset = (view.bounds.height - statusBarOffset - buttonOffset - contentHeight) / 2 + statusBarOffset - 15
        
        logoView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        logoView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: topOffset)
        
        descriptionTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        descriptionTextView.autoPinEdge(.Top, toEdge: .Bottom, ofView: logoView, withOffset: -10)
        descriptionTextView.autoSetDimension(.Width, toSize: 210)
        
        plusView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        plusView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionTextView, withOffset: 10)
        
        glassesImageView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        glassesImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: plusView, withOffset: 15)
        
        glassesTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        glassesTextView.autoPinEdge(.Top, toEdge: .Bottom, ofView: glassesImageView, withOffset: 10)
        glassesTextView.autoSetDimension(.Width, toSize: 280)
        
        nextButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        nextButtonView.autoPinEdge(.Bottom, toEdge: .Top, ofView: dotProgressView, withOffset: -20)
        nextButtonView.autoSetDimension(.Height, toSize: 50)
        nextButtonView.autoSetDimension(.Width, toSize: 230)
        
        dotProgressView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        dotProgressView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -30)
        dotProgressView.autoSetDimension(.Height, toSize: 6)
        dotProgressView.autoSetDimension(.Width, toSize: 230)
        
        super.updateViewConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: false)
        
        super.viewDidAppear(animated)
    }
    
    func pushProfileOnboarding() {
        presentViewController(OnboardingProfileViewController(), animated: false, completion: nil)
    }
    
}

class DotProgressView: UIView {
    private var dotLayers: [CALayer] = []
    
    var activeIndex = 0 {
        didSet {
            updateDots()
        }
    }
    var numberOfDots = 1 {
        didSet {
            updateDots()
        }
    }
    
    private func updateDots() {
        for dot in dotLayers {
            dot.removeFromSuperlayer()
        }
        
        dotLayers.removeAll()
        
        for index in 0..<numberOfDots {
            let dot = CALayer()
            dot.cornerRadius = 3
            dot.backgroundColor = index == activeIndex ? UIColor.Accent.CGColor : UIColor.LightGrey.CGColor
            layer.addSublayer(dot)
            dotLayers.append(dot)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let spacing: CGFloat = 7
        let centerX = bounds.width / 2
        let size: CGFloat = 6
        
        for (index, dot) in dotLayers.enumerate() {
            let multiplier = CGFloat(index) - CGFloat(numberOfDots) / 2
            let x = bounds.origin.x + centerX + multiplier * (size + spacing)
            dot.frame = CGRect(x: x, y: bounds.origin.y, width: size, height: size)
        }
    }
    
}
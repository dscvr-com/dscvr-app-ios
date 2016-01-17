//
//  OnboardingHashtagViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/18/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Mixpanel

class OnboardingHashtagSelectViewController: UIViewController {
    
    // subviews
    private let headlineTextView = UILabel()
    private let backgroundImageView = PlaceholderImageView()
    private let backgroundBlurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    private let imageView = PlaceholderImageView()
    private let loadingInidicatorView = UIActivityIndicatorView()
    private let skipButtonView = ActionButton()
    private let heartButtonView = ActionButton()
    
    private let viewModel = OnboardingHashtagSelectViewModel()
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundImageView.addSubview(backgroundBlurView)
        backgroundImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        backgroundImageView.clipsToBounds = true
        backgroundImageView.contentMode = .ScaleAspectFill
        view.addSubview(backgroundImageView)
        
        headlineTextView.textAlignment = .Center
        headlineTextView.text = "Do you like what you see?"
        headlineTextView.textColor = .whiteColor()
        headlineTextView.font = UIFont.displayOfSize(25, withType: .Thin)
        view.addSubview(headlineTextView)
        
        imageView.placeholderImage = UIImage(named: "optograph-placeholder")!
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        
//        viewModel.currentHashtag.producer
//            .ignoreNil()
//            .map { "\(S3URL)/hashtag-preview/\($0.previewAssetID).jpg" }
//            .flatMap(.Latest) { SDWebImageManager.sharedManager().downloadImageForURL($0) }
//            .startWithNext { image in
//                self.viewModel.loading.value = false
//                self.imageView.image = image
//                self.backgroundImageView.image = image
//            }
        
        loadingInidicatorView.rac_animating <~ viewModel.loading
        loadingInidicatorView.activityIndicatorViewStyle = .White
        view.addSubview(loadingInidicatorView)
        
        skipButtonView.defaultBackgroundColor = .Accent
        skipButtonView.titleLabel?.font = UIFont.iconOfSize(20)
        skipButtonView.setTitle(String.iconWithName(.Cancel), forState: .Normal)
        skipButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        skipButtonView.layer.cornerRadius = 30
        skipButtonView.rac_alpha <~ viewModel.loading.producer.map { $0 ? 0.3 : 1 }
        skipButtonView.rac_userInteractionEnabled <~ viewModel.loading.producer.map(negate)
        skipButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "skipHashtag"))
        view.addSubview(skipButtonView)
        
        heartButtonView.defaultBackgroundColor = .Accent
        heartButtonView.titleLabel?.font = UIFont.iconOfSize(20)
//        heartButtonView.setTitle(String.iconWithName(.HeartFilled), forState: .Normal)
        heartButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        heartButtonView.layer.cornerRadius = 30
        heartButtonView.rac_alpha <~ viewModel.loading.producer.map { $0 ? 0.3 : 1 }
        heartButtonView.rac_userInteractionEnabled <~ viewModel.loading.producer.map(negate)
        heartButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "followHashtag"))
        view.addSubview(heartButtonView)
        
        viewModel.selectedHashtags.producer.startWithNext { [weak self] items in
            if items.count == 3 {
                let hashtagStr = items.map({ "#\($0.name)" }).joinWithSeparator(", ")
                self?.view.window?.rootViewController = OnboardingHashtagSummaryViewController(todoSelectedHashtags: hashtagStr)
            }
        }
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        
        headlineTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        headlineTextView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 75)
        headlineTextView.autoSetDimension(.Width, toSize: 300)
        
        backgroundImageView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        backgroundBlurView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        imageView.autoPinEdge(.Left, toEdge: .Left, ofView: view)
        imageView.autoPinEdge(.Right, toEdge: .Right, ofView: view)
        imageView.autoMatchDimension(.Height, toDimension: .Width, ofView: view, withMultiplier: 3 / 4)
        imageView.autoPinEdge(.Bottom, toEdge: .Top, ofView: skipButtonView, withOffset: -42)
        
        loadingInidicatorView.autoAlignAxis(.Vertical, toSameAxisOfView: imageView)
        loadingInidicatorView.autoAlignAxis(.Horizontal, toSameAxisOfView: imageView)
        
        skipButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view, withOffset: -40)
        skipButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -42)
        skipButtonView.autoSetDimension(.Width, toSize: 60)
        skipButtonView.autoSetDimension(.Height, toSize: 60)
        
        heartButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view, withOffset: 40)
        heartButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -42)
        heartButtonView.autoSetDimension(.Width, toSize: 60)
        heartButtonView.autoSetDimension(.Height, toSize: 60)
        
        super.updateViewConstraints()
    }
    
    func followHashtag() {
        viewModel.followHashtag()
    }
    
    func skipHashtag() {
        viewModel.skipHashtag()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Mixpanel.sharedInstance().timeEvent("View.OnboardingHashtagSelect")
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Mixpanel.sharedInstance().track("View.OnboardingHashtagSelect")
    }
}
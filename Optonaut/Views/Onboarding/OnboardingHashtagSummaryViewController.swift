//
//  OnboardingHashtagSummaryViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 9/27/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import Crashlytics

class OnboardingHashtagSummaryViewController: UIViewController {
    
    // subviews
    private let headlineTextView = UILabel()
    private let subHeadlineTextView = UILabel()
    private let todoSelectedHashtagsView = UILabel()
    private let iconTextView = UILabel()
    private let nextButtonView = HatchedButton()
    
    required init(todoSelectedHashtags: String) {
        todoSelectedHashtagsView.text = todoSelectedHashtags
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .Accent
        
        headlineTextView.numberOfLines = 1
        headlineTextView.textAlignment = .Center
        headlineTextView.text = "Great. All done!"
        headlineTextView.textColor = .whiteColor()
        headlineTextView.font = UIFont.displayOfSize(25, withType: .Thin)
        view.addSubview(headlineTextView)
        
        subHeadlineTextView.textAlignment = .Center
        subHeadlineTextView.text = "You’re following these hashtags:"
        subHeadlineTextView.textColor = .whiteColor()
        subHeadlineTextView.font = UIFont.displayOfSize(20, withType: .Thin)
        view.addSubview(subHeadlineTextView)
        
        todoSelectedHashtagsView.numberOfLines = 0
        todoSelectedHashtagsView.textAlignment = .Center
        todoSelectedHashtagsView.textColor = .whiteColor()
        todoSelectedHashtagsView.font = UIFont.displayOfSize(14, withType: .Semibold)
        view.addSubview(todoSelectedHashtagsView)
        
        iconTextView.text = "Of course you’ll be able to follow other hashtags as well. All you have to do is add them as you go.\r\n\r\nEnjoy!"
        iconTextView.font = UIFont.displayOfSize(20, withType: .Thin)
        iconTextView.numberOfLines = 5
        iconTextView.textAlignment = .Center
        iconTextView.textColor = .whiteColor()
        view.addSubview(iconTextView)
        
        nextButtonView.setTitle("Open feed", forState: .Normal)
        nextButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showFeed"))
        view.addSubview(nextButtonView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        
        headlineTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        headlineTextView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 75)
        headlineTextView.autoSetDimension(.Width, toSize: 300)
        
        subHeadlineTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        subHeadlineTextView.autoPinEdge(.Top, toEdge: .Bottom, ofView: headlineTextView, withOffset: 40)
        subHeadlineTextView.autoSetDimension(.Width, toSize: 300)
        
        todoSelectedHashtagsView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        todoSelectedHashtagsView.autoPinEdge(.Top, toEdge: .Bottom, ofView: subHeadlineTextView, withOffset: 15)
        todoSelectedHashtagsView.autoSetDimension(.Width, toSize: 300)
        
        iconTextView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        iconTextView.autoPinEdge(.Bottom, toEdge: .Top, ofView: nextButtonView, withOffset: -52)
        iconTextView.autoSetDimension(.Width, toSize: 300)
        
        nextButtonView.autoAlignAxis(.Vertical, toSameAxisOfView: view)
        nextButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: view, withOffset: -42)
        nextButtonView.autoSetDimension(.Height, toSize: 60)
        nextButtonView.autoSetDimension(.Width, toSize: 235)
        
        super.updateViewConstraints()
    }
    
    func showFeed() {
        ApiService<EmptyResponse>.put("persons/me", parameters: ["onboarding_version": OnboardingVersion])
            .startWithCompleted {
                self.presentViewController(TabBarViewController(), animated: false, completion: nil)
                SessionService.sessionData?.onboardingVersion = OnboardingVersion
            }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Answers.logContentViewWithName("Onboarding Hashtag Summary",
            contentType: "OnboardingHashtagSummaryView",
            contentId: "",
            customAttributes: [:])
    }

    
}
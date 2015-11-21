//
//  OptographInfoView.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class OptographInfoView: UIView {
    
    weak var navigationController: NavigationController?
    
    var deleteCallback: (() -> ())?
    
    private var viewModel: OptographInfoViewModel!
    
    // subviews
    private let avatarImageView = PlaceholderImageView()
//    private let locationIconView = UILabel()
    private let locationTextView = UILabel()
    private let locationCountryView = UILabel()
//    private let dateView = UILabel()
    private let starButtonView = UIButton()
    private let starsCountView = UILabel()
    private let optionsButtonView = UIButton()
    private let publishingView = UIActivityIndicatorView()
    private let retryButtonView = UIButton()
    
    private var constraintsApplied = false
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clearColor()
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        addSubview(avatarImageView)
        
//        locationIconView.text = String.iconWithName(.Location)
//        locationIconView.font = UIFont.iconOfSize(13)
//        locationIconView.textColor = .whiteColor()
//        addSubview(locationIconView)
        
        locationTextView.font = UIFont.displayOfSize(14.5, withType: .Semibold)
        locationTextView.textColor = .whiteColor()
        locationTextView.adjustsFontSizeToFitWidth = true
        addSubview(locationTextView)
        
        locationCountryView.font = UIFont.displayOfSize(13, withType: .Thin)
        locationCountryView.textColor = .whiteColor()
        locationCountryView.adjustsFontSizeToFitWidth = true
        addSubview(locationCountryView)
        
//        dateView.font = UIFont.displayOfSize(12, withType: .Thin)
//        dateView.textColor = .whiteColor()
//        addSubview(dateView)
        
        starButtonView.titleLabel?.font = UIFont.iconOfSize(23.5)
        starButtonView.setTitle(String.iconWithName(.HeartFilled), forState: .Normal)
        starButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleStar"))
        addSubview(starButtonView)
        
        starsCountView.font = UIFont.displayOfSize(14, withType: .Thin)
        starsCountView.textColor = .whiteColor()
        
        retryButtonView.titleLabel?.font = UIFont.iconOfSize(23.5)
        retryButtonView.setTitle(String.iconWithName(.Redo), forState: .Normal)
        retryButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "retryPublish"))
        addSubview(retryButtonView)
        
        addSubview(publishingView)

        addSubview(starsCountView)
        
        optionsButtonView.titleLabel?.font = UIFont.iconOfSize(23.5)
        optionsButtonView.setTitle(String.iconWithName(.MoreOptions), forState: .Normal)
        optionsButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        optionsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "didTapOptions"))
        addSubview(optionsButtonView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        avatarImageView.autoPinEdge(.Top, toEdge: .Top, ofView: self, withOffset: 19)
        avatarImageView.autoPinEdge(.Left, toEdge: .Left, ofView: self, withOffset: 20)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 40, height: 40))
        
        //        locationIconView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: 5)
        //        locationIconView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 12)
        //        locationIconView.autoSetDimension(.Width, toSize: 15)
        //        locationIconView.autoSetDimension(.Height, toSize: 15)
        
        locationTextView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: 4)
        locationTextView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 12)
        //            locationTextView.autoPinEdge(.Right, toEdge: .Left, ofView: optionsButtonView, withOffset: 12)
        // TODO fix this line. worst code ever. hate!
        locationTextView.autoSetDimension(.Width, toSize: UIScreen.mainScreen().bounds.width - 72 - 115)
        
        //        locationTextView.autoPinEdge(.Top, toEdge: .Top, ofView: locationIconView, withOffset: -2)
        //        locationTextView.autoPinEdge(.Left, toEdge: .Right, ofView: locationIconView, withOffset: 4)
        
        //        locationCountryView.autoPinEdge(.Top, toEdge: .Top, ofView: locationTextView)
        //        locationCountryView.autoPinEdge(.Left, toEdge: .Right, ofView: locationTextView, withOffset: 5)
        locationCountryView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: avatarImageView, withOffset: -1)
        locationCountryView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 12)
        
        //        dateView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: avatarImageView, withOffset: 1)
        //        dateView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 15)
        
        starButtonView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        starButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: self, withOffset: -23.5) // 3.5pt extra for heart border
        
        starsCountView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        starsCountView.autoPinEdge(.Right, toEdge: .Left, ofView: starButtonView, withOffset: -10)
        
        retryButtonView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        retryButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: self, withOffset: -23.5)
        
        publishingView.autoPinEdge(.Right, toEdge: .Right, ofView: self, withOffset: -23.5)
        publishingView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        
        optionsButtonView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        optionsButtonView.autoPinEdge(.Right, toEdge: .Left, ofView: starButtonView, withOffset: -31)
        
    }
    
    func bindViewModel(optograph: Optograph) {
        viewModel = OptographInfoViewModel(optograph: optograph)
        
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        locationTextView.rac_text <~ viewModel.locationText
        locationCountryView.rac_text <~ viewModel.locationCountry
        //        dateView.rac_text <~ viewModel.timeSinceCreated
        starButtonView.rac_titleColor <~ viewModel.isStarred.producer.map { $0 ? .Accent : .Grey }
        starsCountView.rac_text <~ viewModel.starsCount.producer.map { "\($0)" }
        
        viewModel.status.producer
            .skipRepeats()
            .startWithNext { [unowned self] status in
                switch status {
                case .Published:
                    self.starButtonView.hidden = false
                    self.starsCountView.hidden = false
                    self.retryButtonView.hidden = true
                    self.publishingView.hidden = true
                    self.publishingView.stopAnimating()
                case .Publishing, .Stitching:
                    self.starButtonView.hidden = true
                    self.starsCountView.hidden = true
                    self.retryButtonView.hidden = true
                    self.publishingView.hidden = false
                    self.publishingView.startAnimating()
                case .Offline, .Guest:
                    self.starButtonView.hidden = true
                    self.starsCountView.hidden = true
                    self.retryButtonView.hidden = false
                    self.publishingView.hidden = true
                    self.publishingView.stopAnimating()
                }
        }
    }
    
    func pushProfile() {
        navigationController?.pushViewController(ProfileTableViewController(personID: viewModel.optograph.person.ID), animated: true)
    }
    
    func toggleStar() {
        if !SessionService.isLoggedIn {
            let alert = UIAlertController(title: "Please login first", message: "In order to like this Optograph you need to login or signup.\nDon't worry, it just takes 30 seconds.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Login now", style: .Default, handler: { [weak self] _ in
                self?.navigationController?.presentViewController(LoginViewController(), animated: false, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Later", style: .Cancel, handler: { _ in return }))
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        viewModel.toggleLike()
    }
    
    func retryPublish() {
        if !SessionService.isLoggedIn {
            let alert = UIAlertController(title: "Please login first", message: "In order to upload this Optograph you need to login or signup.\nDon't worry, it just takes 30 seconds.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Login now", style: .Default, handler: { [weak self] _ in
                self?.navigationController?.presentViewController(LoginViewController(), animated: false, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "Later", style: .Cancel, handler: { _ in return }))
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        if !Reachability.connectedToNetwork() {
            NotificationService.push("No internet connection", level: .Warning)
            return
        }
        
        viewModel.retryPublish()
    }
    
}



// MARK: - OptographOptions
extension OptographInfoView: OptographOptions {
    
    func didTapOptions() {
        showOptions(viewModel.optograph, deleteCallback: deleteCallback)
    }
    
}
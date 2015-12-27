//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SwiftyUserDefaults

class ProfileHeaderTableViewCell: UITableViewCell {
    
    weak var navigationController: NavigationController?
    
    var viewModel: ProfileViewModel!
    var isMe: Bool!
    
    // subviews
    private let avatarBackgroundImageView = PlaceholderImageView()
    private let avatarBackgroundBlurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    private let avatarImageView = PlaceholderImageView()
    private let displayNameView = UILabel()
    private let userNameView = UILabel()
    private let textView = UILabel()
    private let followButtonView = UIButton()
    private let settingsButtonView = UIButton()
    private let editProfileButtonView = UIButton()
    private let followersHeadingView = UILabel()
    private let followersCountView = UILabel()
    private let verticalLineView = UIView()
    private let followedHeadingView = UILabel()
    private let followedCountView = UILabel()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        avatarBackgroundImageView.addSubview(avatarBackgroundBlurView)
        avatarBackgroundImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarBackgroundImageView.clipsToBounds = true
        avatarBackgroundImageView.contentMode = .ScaleAspectFill
        contentView.addSubview(avatarBackgroundImageView)
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 42
        avatarImageView.clipsToBounds = true
        contentView.addSubview(avatarImageView)
        
        displayNameView.font = UIFont.robotoOfSize(15, withType: .Medium)
        displayNameView.textColor = .whiteColor()
        contentView.addSubview(displayNameView)
        
        userNameView.font = UIFont.robotoOfSize(12, withType: .Light)
        userNameView.textColor = .whiteColor()
        contentView.addSubview(userNameView)
        
        textView.numberOfLines = 2
        textView.textAlignment = .Center
        textView.font = UIFont.robotoOfSize(13, withType: .Light)
        textView.textColor = .whiteColor()
        contentView.addSubview(textView)
        
        followButtonView.backgroundColor = .whiteColor()
        followButtonView.layer.borderWidth = 1
        followButtonView.layer.borderColor = UIColor.Accent.CGColor
        followButtonView.layer.cornerRadius = 5
        followButtonView.layer.masksToBounds = true
        followButtonView.setTitleColor(UIColor.Accent, forState: .Normal)
        followButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Regular)
        followButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleFollow"))
        contentView.addSubview(followButtonView)
        
        settingsButtonView.backgroundColor = .whiteColor()
        settingsButtonView.layer.borderWidth = 1
        settingsButtonView.layer.borderColor = UIColor.Accent.CGColor
        settingsButtonView.layer.cornerRadius = 5
        settingsButtonView.layer.masksToBounds = true
//        settingsButtonView.setTitle(String.icomoonWithName(.Cog), forState: .Normal)
        settingsButtonView.setTitleColor(UIColor.Accent, forState: .Normal)
//        settingsButtonView.titleLabel?.font = .icomoonOfSize(16)
        settingsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showSettingsActions"))
        contentView.addSubview(settingsButtonView)
        
        editProfileButtonView.backgroundColor = .whiteColor()
        editProfileButtonView.layer.borderWidth = 1
        editProfileButtonView.layer.borderColor = UIColor.Accent.CGColor
        editProfileButtonView.layer.cornerRadius = 5
        editProfileButtonView.layer.masksToBounds = true
        editProfileButtonView.setTitle("Edit", forState: .Normal)
        editProfileButtonView.setTitleColor(UIColor.Accent, forState: .Normal)
        editProfileButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Regular)
        editProfileButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "editProfile"))
        contentView.addSubview(editProfileButtonView)
        
        followersHeadingView.text = "Followers"
        followersHeadingView.font = .robotoOfSize(11, withType: .Regular)
        followersHeadingView.textColor = .blackColor()
        contentView.addSubview(followersHeadingView)
        
        followersCountView.font = .robotoOfSize(13, withType: .Medium)
        followersCountView.textColor = .blackColor()
        contentView.addSubview(followersCountView)
        
        verticalLineView.backgroundColor = UIColor(0xe5e5e5)
        contentView.addSubview(verticalLineView)
        
        followedHeadingView.text = "Following"
        followedHeadingView.font = .robotoOfSize(11, withType: .Regular)
        followedHeadingView.textColor = .blackColor()
        contentView.addSubview(followedHeadingView)
        
        followedCountView.font = .robotoOfSize(13, withType: .Medium)
        followedCountView.textColor = .blackColor()
        contentView.addSubview(followedCountView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        avatarBackgroundImageView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        avatarBackgroundImageView.autoSetDimension(.Height, toSize: 213)
        
        avatarBackgroundBlurView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        avatarImageView.autoPinEdge(.Top, toEdge: .Top,  ofView: contentView, withOffset: 39)
        avatarImageView.autoAlignAxisToSuperviewAxis(.Vertical)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 84, height: 84))
        
        displayNameView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 17)
        displayNameView.autoAlignAxisToSuperviewAxis(.Vertical)
        
        userNameView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: displayNameView, withOffset: -2)
        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: displayNameView, withOffset: 5)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: displayNameView, withOffset: 5)
        textView.autoPinEdge(.Left, toEdge: .Left,  ofView: contentView, withOffset: 19)
        textView.autoPinEdge(.Right, toEdge: .Right,  ofView: contentView, withOffset: -19)
        
        followButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        followButtonView.autoPinEdge(.Right, toEdge: .Left, ofView: settingsButtonView, withOffset: -3)
        followButtonView.autoSetDimensionsToSize(CGSize(width: 80, height: 31))
        
        settingsButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        settingsButtonView.autoPinEdge(.Right, toEdge: .Right,  ofView: contentView, withOffset: -19)
        settingsButtonView.autoSetDimensionsToSize(CGSize(width: 40, height: 31))
        
        editProfileButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        editProfileButtonView.autoPinEdge(.Right, toEdge: .Left, ofView: settingsButtonView, withOffset: -3)
        editProfileButtonView.autoSetDimensionsToSize(CGSize(width: 80, height: 31))
        
        followersHeadingView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        followersHeadingView.autoPinEdge(.Left, toEdge: .Left,  ofView: contentView, withOffset: 19)
        
        followersCountView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: followButtonView)
        followersCountView.autoPinEdge(.Left, toEdge: .Left, ofView: followersHeadingView)
        
        verticalLineView.autoPinEdge(.Top, toEdge: .Top, ofView: followersHeadingView)
        verticalLineView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: followersCountView)
        verticalLineView.autoPinEdge(.Left, toEdge: .Right, ofView: followersHeadingView, withOffset: 12)
        verticalLineView.autoSetDimension(.Width, toSize: 1)
        
        followedHeadingView.autoPinEdge(.Top, toEdge: .Top, ofView: followersHeadingView)
        followedHeadingView.autoPinEdge(.Left, toEdge: .Right, ofView: verticalLineView, withOffset: 12)
        
        followedCountView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: followButtonView)
        followedCountView.autoPinEdge(.Left, toEdge: .Left, ofView: followedHeadingView)
        
        super.updateConstraints()
    }
    
    func bindViewModel(personID: UUID) {
        viewModel = ProfileViewModel(ID:  personID)
        
        isMe = Defaults[.SessionPersonID] == personID
        
        avatarBackgroundImageView.rac_url <~ viewModel.avatarImageUrl
        
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        
        displayNameView.rac_text <~ viewModel.displayName
        
        userNameView.rac_text <~ viewModel.userName.producer.map { "@\($0)" }
        
        textView.rac_text <~ viewModel.text
        
        followButtonView.rac_title <~ viewModel.isFollowed.producer.map { $0 ? "Unfollow" : "Follow" }
        followButtonView.hidden = isMe
        
        editProfileButtonView.hidden = !isMe
        
        followersCountView.rac_text <~ viewModel.followersCount.producer.map { "\($0)" }
        
        followedCountView.rac_text <~ viewModel.followedCount.producer.map { "\($0)" }
    }
    
    func editProfile() {
        navigationController?.pushViewController(EditProfileViewController(), animated: false)
    }
    
    func toggleFollow() {
        if !SessionService.isLoggedIn {
            let alert = UIAlertController(title: "Please login first", message: "In order to follow \(viewModel.displayName.value) you need to login or signup.\nDon't worry, it just takes 30 seconds.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Sign in", style: .Cancel, handler: { [weak self] _ in
                self?.window?.rootViewController = LoginViewController()
            }))
            alert.addAction(UIAlertAction(title: "Later", style: .Default, handler: { _ in return }))
            self.navigationController?.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        viewModel.toggleFollow()
    }
    
    func showSettingsActions() {
        let settingsSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        if isMe! {
            settingsSheet.addAction(UIAlertAction(title: "Sign out", style: .Destructive, handler: { _ in
                SessionService.logout()
            }))
        } else {
            settingsSheet.addAction(UIAlertAction(title: "Report user", style: .Destructive, handler: { _ in
                let confirmAlert = UIAlertController(title: "Are you sure?", message: "This action will message one of the moderators.", preferredStyle: .Alert)
                confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
                confirmAlert.addAction(UIAlertAction(title: "Report", style: .Destructive, handler: { _ in
                    self.viewModel.person.report().start()
                }))
                self.navigationController?.presentViewController(confirmAlert, animated: true, completion: nil)
            }))
        }
        
        settingsSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        
        navigationController?.presentViewController(settingsSheet, animated: true, completion: nil)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}

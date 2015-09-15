//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ProfileHeaderTableViewCell: UITableViewCell {
    
    weak var navigationController: NavigationController?
    
    var viewModel: ProfileViewModel!
    
    // subviews
    private let avatarBackgroundImageView = UIImageView()
    private let avatarBackgroundBlurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .Dark)
        return UIVisualEffectView(effect: blurEffect)
    }()
    private let avatarImageView = UIImageView()
    private let fullNameView = UILabel()
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
        avatarBackgroundImageView.clipsToBounds = true
        avatarBackgroundImageView.contentMode = .ScaleAspectFill
        contentView.addSubview(avatarBackgroundImageView)
        
        avatarImageView.layer.cornerRadius = 42
        avatarImageView.clipsToBounds = true
        contentView.addSubview(avatarImageView)
        
        fullNameView.font = UIFont.robotoOfSize(15, withType: .Medium)
        fullNameView.textColor = .whiteColor()
        contentView.addSubview(fullNameView)
        
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
        followButtonView.layer.borderColor = BaseColor.CGColor
        followButtonView.layer.cornerRadius = 5
        followButtonView.layer.masksToBounds = true
        followButtonView.setTitleColor(BaseColor, forState: .Normal)
        followButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Regular)
        followButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleFollow"))
        contentView.addSubview(followButtonView)
        
        settingsButtonView.backgroundColor = .whiteColor()
        settingsButtonView.layer.borderWidth = 1
        settingsButtonView.layer.borderColor = BaseColor.CGColor
        settingsButtonView.layer.cornerRadius = 5
        settingsButtonView.layer.masksToBounds = true
        settingsButtonView.setTitle(String.icomoonWithName(.Cog), forState: .Normal)
        settingsButtonView.setTitleColor(BaseColor, forState: .Normal)
        settingsButtonView.titleLabel?.font = .icomoonOfSize(16)
        settingsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showSettingsActions"))
        contentView.addSubview(settingsButtonView)
        
        editProfileButtonView.backgroundColor = .whiteColor()
        editProfileButtonView.layer.borderWidth = 1
        editProfileButtonView.layer.borderColor = BaseColor.CGColor
        editProfileButtonView.layer.cornerRadius = 5
        editProfileButtonView.layer.masksToBounds = true
        editProfileButtonView.setTitle("Edit", forState: .Normal)
        editProfileButtonView.setTitleColor(BaseColor, forState: .Normal)
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
        
        fullNameView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 17)
        fullNameView.autoAlignAxisToSuperviewAxis(.Vertical)
        
        userNameView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: fullNameView, withOffset: -2)
        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: fullNameView, withOffset: 5)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: fullNameView, withOffset: 5)
        textView.autoPinEdge(.Left, toEdge: .Left,  ofView: contentView, withOffset: 19)
        textView.autoPinEdge(.Right, toEdge: .Right,  ofView: contentView, withOffset: -19)
        
        followButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        followButtonView.autoPinEdge(.Right, toEdge: .Right,  ofView: contentView, withOffset: -19)
        followButtonView.autoSetDimensionsToSize(CGSize(width: 110, height: 31))
        
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
    
    func bindViewModel(personId: UUID) {
        viewModel = ProfileViewModel(id: personId)
        
        let isMe = SessionService.sessionData!.id == personId
        
        avatarBackgroundImageView.rac_image <~ viewModel.avatarImage
        
        avatarImageView.rac_image <~ viewModel.avatarImage
        
        fullNameView.rac_text <~ viewModel.fullName
        
        userNameView.rac_text <~ viewModel.userName.producer.map { "@\($0)" }
        
        textView.rac_text <~ viewModel.text
        
        followButtonView.rac_title <~ viewModel.isFollowed.producer.map { $0 ? "Unfollow" : "Follow" }
        followButtonView.hidden = isMe
        
        settingsButtonView.hidden = !isMe
        
        editProfileButtonView.hidden = !isMe
        
        followersCountView.rac_text <~ viewModel.followersCount.producer.map { "\($0)" }
        
        followedCountView.rac_text <~ viewModel.followedCount.producer.map { "\($0)" }
    }
    
    func editProfile() {
        navigationController?.pushViewController(EditProfileViewController(), animated: false)
    }
    
    func toggleFollow() {
        viewModel.toggleFollow()
    }
    
    func showSettingsActions() {
        let settingsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        settingsAlert.addAction(UIAlertAction(title: "Sign out", style: .Destructive, handler: { _ in
            SessionService.logout()
        }))
        
        settingsAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        
        navigationController?.presentViewController(settingsAlert, animated: true, completion: nil)
    }
    
}

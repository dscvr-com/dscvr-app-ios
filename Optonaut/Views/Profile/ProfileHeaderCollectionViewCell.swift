//
//  ProfileHeaderCollectionViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 23/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import ReactiveCocoa
import SwiftyUserDefaults

class ProfileHeaderCollectionViewCell: UICollectionViewCell {
    
    weak var navigationController: NavigationController?
    
    weak var viewModel: ProfileViewModel!
    var isMe: Bool!
    
    // subviews
    private let avatarImageView = PlaceholderImageView()
    private let displayNameView = UILabel()
    private let textView = UILabel()
    private let followButtonView = UIButton()
    private let settingsButtonView = UIButton()
    private let editProfileButtonView = UIButton()
    private let postHeadingView = UILabel()
    private let postCountView = UILabel()
    private let followersHeadingView = UILabel()
    private let followersCountView = UILabel()
    private let followingHeadingView = UILabel()
    private let followingCountView = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .whiteColor()
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 42
        avatarImageView.clipsToBounds = true
        contentView.addSubview(avatarImageView)
        
        displayNameView.font = UIFont.displayOfSize(15, withType: .Semibold)
        displayNameView.textColor = .Accent
        displayNameView.textAlignment = .Center
        contentView.addSubview(displayNameView)
        
        textView.numberOfLines = 2
        textView.textAlignment = .Center
        textView.font = UIFont.displayOfSize(12, withType: .Regular)
        textView.textColor = UIColor(0x979797)
        contentView.addSubview(textView)
        
        followButtonView.backgroundColor = UIColor(0xcacaca)
        followButtonView.layer.cornerRadius = 5
        followButtonView.layer.masksToBounds = true
        followButtonView.setTitleColor(.whiteColor(), forState: .Normal)
        followButtonView.titleLabel?.font = .displayOfSize(11, withType: .Semibold)
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
        
        postHeadingView.text = "Posts"
        postHeadingView.textAlignment = .Center
        postHeadingView.font = .displayOfSize(12, withType: .Semibold)
        postHeadingView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(postHeadingView)
        
        postCountView.font = .displayOfSize(12, withType: .Semibold)
        postCountView.textAlignment = .Center
        postCountView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(postCountView)
        
        followersHeadingView.text = "Followers"
        followersHeadingView.textAlignment = .Center
        followersHeadingView.font = .displayOfSize(12, withType: .Semibold)
        followersHeadingView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(followersHeadingView)
        
        followersCountView.font = .displayOfSize(12, withType: .Semibold)
        followersCountView.textAlignment = .Center
        followersCountView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(followersCountView)
        
        followingHeadingView.text = "Following"
        followingHeadingView.textAlignment = .Center
        followingHeadingView.font = .displayOfSize(12, withType: .Semibold)
        followingHeadingView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(followingHeadingView)
        
        followingCountView.font = .displayOfSize(12, withType: .Semibold)
        followingCountView.textAlignment = .Center
        followingCountView.textColor = UIColor(0xbdbdbd)
        contentView.addSubview(followingCountView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = contentView.frame.size
        
        avatarImageView.frame = CGRect(x: size.width / 2 - 42, y: 20, width: 84, height: 84)
        displayNameView.align(.UnderCentered, relativeTo: avatarImageView, padding: 10, width: size.width - 28, height: 17)
        textView.align(.UnderCentered, relativeTo: displayNameView, padding: 10, width: size.width - 28, height: calcTextHeight(textView.text!, withWidth: size.width - 28, andFont: textView.font))
        followButtonView.align(.UnderCentered, relativeTo: textView, padding: 15, width: 180, height: 27)
        
        let metricWidth = size.width / 3
        postCountView.anchorInCorner(.BottomLeft, xPad: 0, yPad: 33, width: metricWidth, height: 14)
        postHeadingView.anchorInCorner(.BottomLeft, xPad: 0, yPad: 19, width: metricWidth, height: 14)
        followersCountView.anchorToEdge(.Bottom, padding: 33, width: metricWidth, height: 14)
        followersHeadingView.anchorToEdge(.Bottom, padding: 19, width: metricWidth, height: 14)
        followingCountView.anchorInCorner(.BottomRight, xPad: 0, yPad: 33, width: metricWidth, height: 14)
        followingHeadingView.anchorInCorner(.BottomRight, xPad: 0, yPad: 19, width: metricWidth, height: 14)
    }
    
    func bindViewModel(viewModel: ProfileViewModel) {
//        viewModel = ProfileViewModel(ID:  personID)
        
//        isMe = Defaults[.SessionPersonID] == personID
        isMe = true
        
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        
        displayNameView.rac_text <~ viewModel.displayName
        
        textView.rac_text <~ viewModel.text
        
        followButtonView.rac_title <~ viewModel.isFollowed.producer.map { $0 ? "Unfollow" : "Follow".uppercaseString }
//        followButtonView.hidden = isMe
        
        editProfileButtonView.hidden = !isMe
        
        followersCountView.rac_text <~ viewModel.followersCount.producer.map { "\($0)" }
        postCountView.rac_text <~ viewModel.followersCount.producer.map { "\($0)" }
        followingCountView.rac_text <~ viewModel.followingCount.producer.map { "\($0)" }
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
        
//        viewModel.toggleFollow()
    }
    
    
}

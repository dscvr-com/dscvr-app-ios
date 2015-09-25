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
    private let avatarImageView = PlaceholderImageView()
    private let displayNameView = UILabel()
    private let userNameView = UILabel()
    private let textView = UILabel()
    private let followButtonView = UIButton()
    private let settingsButtonView = UIButton()
    private let editProfileButtonView = UIButton()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .blackColor()
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 42
        avatarImageView.clipsToBounds = true
        contentView.addSubview(avatarImageView)
        
        displayNameView.font = UIFont.robotoOfSize(22, withType: .SemiBold)
        displayNameView.textColor = .whiteColor()
        contentView.addSubview(displayNameView)
        
        userNameView.font = UIFont.robotoOfSize(18, withType: .Regular)
        userNameView.textColor = .whiteColor()
        contentView.addSubview(userNameView)
        
        textView.numberOfLines = 4
        textView.font = UIFont.robotoOfSize(12, withType: .Regular)
        textView.textColor = .whiteColor()
        contentView.addSubview(textView)
        
        followButtonView.backgroundColor = .whiteColor()
        followButtonView.layer.borderWidth = 1
        followButtonView.layer.borderColor = UIColor.Accent.CGColor
        followButtonView.layer.cornerRadius = 6
        followButtonView.layer.masksToBounds = true
        followButtonView.setTitleColor(UIColor.Accent, forState: .Normal)
        followButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Regular)
        followButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleFollow"))
        contentView.addSubview(followButtonView)
        
        settingsButtonView.backgroundColor = .whiteColor()
        settingsButtonView.layer.borderWidth = 1
        settingsButtonView.layer.borderColor = UIColor.Accent.CGColor
        settingsButtonView.layer.cornerRadius = 6
        settingsButtonView.layer.masksToBounds = true
        settingsButtonView.setTitle(String.icomoonWithName(.Cog), forState: .Normal)
        settingsButtonView.setTitleColor(UIColor.Accent, forState: .Normal)
        settingsButtonView.titleLabel?.font = .icomoonOfSize(16)
        settingsButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showSettingsActions"))
        contentView.addSubview(settingsButtonView)
        
        editProfileButtonView.backgroundColor = .whiteColor()
        editProfileButtonView.layer.borderWidth = 1
        editProfileButtonView.layer.borderColor = UIColor.Accent.CGColor
        editProfileButtonView.layer.cornerRadius = 6
        editProfileButtonView.layer.masksToBounds = true
        editProfileButtonView.setTitle("Edit", forState: .Normal)
        editProfileButtonView.setTitleColor(UIColor.Accent, forState: .Normal)
        editProfileButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Regular)
        editProfileButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "editProfile"))
        contentView.addSubview(editProfileButtonView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
        avatarImageView.autoPinEdge(.Top, toEdge: .Top,  ofView: contentView, withOffset: 60)
        avatarImageView.autoPinEdge(.Left, toEdge: .Left,  ofView: contentView, withOffset: 30)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 84, height: 84))
        
        displayNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: 5)
        displayNameView.autoPinEdge(.Left, toEdge: .Right,  ofView: avatarImageView, withOffset: 20)
        displayNameView.autoPinEdge(.Right, toEdge: .Right,  ofView: contentView, withOffset: -30)
        
        userNameView.autoPinEdge(.Top, toEdge: .Bottom, ofView: displayNameView, withOffset: 1)
        userNameView.autoPinEdge(.Left, toEdge: .Right,  ofView: avatarImageView, withOffset: 20)
        userNameView.autoPinEdge(.Right, toEdge: .Right,  ofView: contentView, withOffset: -30)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: userNameView, withOffset: 9)
        textView.autoPinEdge(.Left, toEdge: .Right,  ofView: avatarImageView, withOffset: 20)
        textView.autoPinEdge(.Right, toEdge: .Right,  ofView: contentView, withOffset: -30)
        
//        followButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
//        followButtonView.autoPinEdge(.Right, toEdge: .Right,  ofView: contentView, withOffset: -19)
//        followButtonView.autoSetDimensionsToSize(CGSize(width: 110, height: 31))
//        
//        settingsButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
//        settingsButtonView.autoPinEdge(.Right, toEdge: .Right,  ofView: contentView, withOffset: -19)
//        settingsButtonView.autoSetDimensionsToSize(CGSize(width: 40, height: 31))
//        
//        editProfileButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
//        editProfileButtonView.autoPinEdge(.Right, toEdge: .Left, ofView: settingsButtonView, withOffset: -3)
//        editProfileButtonView.autoSetDimensionsToSize(CGSize(width: 80, height: 31))
        
        super.updateConstraints()
    }
    
    func bindViewModel(personId: UUID) {
        viewModel = ProfileViewModel(id: personId)
        
        let isMe = SessionService.sessionData!.id == personId
        
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        
        displayNameView.rac_text <~ viewModel.displayName
        
        userNameView.rac_text <~ viewModel.userName.producer.map { "@\($0)" }
        
        textView.rac_text <~ viewModel.text
        
        followButtonView.rac_title <~ viewModel.isFollowed.producer.map { $0 ? "Unfollow" : "Follow" }
        followButtonView.hidden = isMe
        
        settingsButtonView.hidden = !isMe
        
        editProfileButtonView.hidden = !isMe
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
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}

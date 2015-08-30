//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ProfileHeaderViewController: UIViewController {
    
    let viewModel: ProfileViewModel
    
    let isMe: Bool
    
    // subviews
    let avatarBackgroundImageView = UIImageView()
    var avatarBackgroundBlurView: UIVisualEffectView!
    let avatarImageView = UIImageView()
    let fullNameView = UILabel()
    let userNameView = UILabel()
    let textView = UILabel()
    let followButtonView = UIButton()
    let logoutButtonView = UIButton()
    let editProfileButtonView = UIButton()
    let followersHeadingView = UILabel()
    let followersCountView = UILabel()
    let verticalLineView = UIView()
    let followedHeadingView = UILabel()
    let followedCountView = UILabel()
    
    required init(personId: UUID) {
        viewModel = ProfileViewModel(id: personId)
        isMe = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultsKeys.PersonId.rawValue) as! UUID == personId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
        let blurEffect = UIBlurEffect(style: .Dark)
        avatarBackgroundBlurView = UIVisualEffectView(effect: blurEffect)
        avatarBackgroundImageView.addSubview(avatarBackgroundBlurView)
        avatarBackgroundImageView.clipsToBounds = true
        avatarBackgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
        avatarBackgroundImageView.rac_image <~ viewModel.avatarImage
        view.addSubview(avatarBackgroundImageView)
        
        avatarImageView.layer.cornerRadius = 42
        avatarImageView.clipsToBounds = true
        avatarImageView.rac_image <~ viewModel.avatarImage
        view.addSubview(avatarImageView)
        
        fullNameView.font = UIFont.robotoOfSize(15, withType: .Medium)
        fullNameView.textColor = .whiteColor()
        fullNameView.rac_text <~ viewModel.fullName
        view.addSubview(fullNameView)
        
        userNameView.font = UIFont.robotoOfSize(12, withType: .Light)
        userNameView.textColor = .whiteColor()
        userNameView.rac_text <~ viewModel.userName.producer .map { "@\($0)" }
        view.addSubview(userNameView)
        
        textView.numberOfLines = 2
        textView.textAlignment = .Center
        textView.font = UIFont.robotoOfSize(13, withType: .Light)
        textView.textColor = .whiteColor()
        textView.rac_text <~ viewModel.text
        view.addSubview(textView)
        
        followButtonView.backgroundColor = .whiteColor()
        followButtonView.layer.borderWidth = 1
        followButtonView.layer.borderColor = BaseColor.CGColor
        followButtonView.layer.cornerRadius = 5
        followButtonView.layer.masksToBounds = true
        followButtonView.setTitleColor(BaseColor, forState: .Normal)
        followButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Regular)
        viewModel.isFollowed.producer
            .start(next: { isFollowed in
                let title = isFollowed ? "Unfollow" : "Follow"
                self.followButtonView.setTitle(title, forState: .Normal)
            })
        followButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.toggleFollow()
            return RACSignal.empty()
        })
        followButtonView.hidden = isMe
        view.addSubview(followButtonView)
        
        logoutButtonView.backgroundColor = .whiteColor()
        logoutButtonView.layer.borderWidth = 1
        logoutButtonView.layer.borderColor = BaseColor.CGColor
        logoutButtonView.layer.cornerRadius = 5
        logoutButtonView.layer.masksToBounds = true
        logoutButtonView.setTitle(String.icomoonWithName(.LogOut), forState: .Normal)
        logoutButtonView.setTitleColor(BaseColor, forState: .Normal)
        logoutButtonView.titleLabel?.font = .icomoonOfSize(16)
        logoutButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.logout()
            return RACSignal.empty()
        })
        logoutButtonView.hidden = !isMe
        view.addSubview(logoutButtonView)
        
        editProfileButtonView.backgroundColor = .whiteColor()
        editProfileButtonView.layer.borderWidth = 1
        editProfileButtonView.layer.borderColor = BaseColor.CGColor
        editProfileButtonView.layer.cornerRadius = 5
        editProfileButtonView.layer.masksToBounds = true
        editProfileButtonView.setTitle("Edit", forState: .Normal)
        editProfileButtonView.setTitleColor(BaseColor, forState: .Normal)
        editProfileButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Regular)
        editProfileButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.editProfile()
            return RACSignal.empty()
        })
        editProfileButtonView.hidden = !isMe
        view.addSubview(editProfileButtonView)
        
        followersHeadingView.text = "Followers"
        followersHeadingView.font = .robotoOfSize(11, withType: .Regular)
        followersHeadingView.textColor = .blackColor()
        view.addSubview(followersHeadingView)
        
        followersCountView.rac_text <~ viewModel.followersCount.producer .map { "\($0)" }
        followersCountView.font = .robotoOfSize(13, withType: .Medium)
        followersCountView.textColor = .blackColor()
        view.addSubview(followersCountView)
        
        verticalLineView.backgroundColor = UIColor(0xe5e5e5)
        view.addSubview(verticalLineView)
        
        followedHeadingView.text = "Following"
        followedHeadingView.font = .robotoOfSize(11, withType: .Regular)
        followedHeadingView.textColor = .blackColor()
        view.addSubview(followedHeadingView)
        
        followedCountView.rac_text <~ viewModel.followedCount.producer .map { "\($0)" }
        followedCountView.font = .robotoOfSize(13, withType: .Medium)
        followedCountView.textColor = .blackColor()
        view.addSubview(followedCountView)
    }
    
    override func updateViewConstraints() {
        avatarBackgroundImageView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        avatarBackgroundImageView.autoSetDimension(.Height, toSize: 213)
        
        avatarBackgroundBlurView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        avatarImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 39)
        avatarImageView.autoAlignAxisToSuperviewAxis(.Vertical)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 84, height: 84))
        
        fullNameView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 17)
        fullNameView.autoAlignAxisToSuperviewAxis(.Vertical)
        
        userNameView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: fullNameView, withOffset: -2)
        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: fullNameView, withOffset: 5)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: fullNameView, withOffset: 5)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        
        followButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        followButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        followButtonView.autoSetDimensionsToSize(CGSize(width: 110, height: 31))
        
        logoutButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        logoutButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        logoutButtonView.autoSetDimensionsToSize(CGSize(width: 40, height: 31))
        
        editProfileButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        editProfileButtonView.autoPinEdge(.Right, toEdge: .Left, ofView: logoutButtonView, withOffset: -3)
        editProfileButtonView.autoSetDimensionsToSize(CGSize(width: 80, height: 31))
        
        followersHeadingView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        followersHeadingView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        
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
        
        super.updateViewConstraints()
    }
    
    private func editProfile() {
        navigationController?.pushViewController(EditProfileViewController(), animated: false)
    }
    
    private func logout() {
        let refreshAlert = UIAlertController(title: "You're about to log out...", message: "Really? Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Sign out", style: .Destructive, handler: { (action: UIAlertAction!) in
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationKeys.Logout.rawValue, object: nil)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
    }
    
}

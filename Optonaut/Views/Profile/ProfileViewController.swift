//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ProfileViewController: UIViewController, TransparentNavbar {
    
    var viewModel: ProfileViewModel
    
    // subviews
    let avatarBackgroundImageView = UIImageView()
    var avatarBackgroundBlurView: UIVisualEffectView!
    let avatarImageView = UIImageView()
    let nameView = UILabel()
    let userNameView = UILabel()
    let bioView = UILabel()
    let followButtonView = UIButton()
    let logoutButtonView = UIButton()
    let editProfileButtonView = UIButton()
    let followersHeadingView = UILabel()
    let followersCountView = UILabel()
    let verticalLineView = UIView()
    let followingHeadingView = UILabel()
    let followingCountView = UILabel()
    var optographsView: UIView!
    
    var isMe = false
    
    required init(userId: Int) {
        viewModel = ProfileViewModel(id: userId)
        isMe = NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultsKeys.UserId.rawValue) == userId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        viewModel = ProfileViewModel(id: 0)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
        let blurEffect = UIBlurEffect(style: .Dark)
        avatarBackgroundBlurView = UIVisualEffectView(effect: blurEffect)
        avatarBackgroundImageView.addSubview(avatarBackgroundBlurView)
        avatarBackgroundImageView.clipsToBounds = true
        avatarBackgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
        view.addSubview(avatarBackgroundImageView)
        
        avatarImageView.layer.cornerRadius = 42
        avatarImageView.clipsToBounds = true
        view.addSubview(avatarImageView)
        
        viewModel.avatarUrl.producer
            |> start(next: { url in
                if let avatarUrl = NSURL(string: url) {
                    self.avatarImageView.sd_setImageWithURL(avatarUrl, placeholderImage: UIImage(named: "avatar-placeholder"))
                    self.avatarBackgroundImageView.sd_setImageWithURL(avatarUrl, placeholderImage: UIImage(named: "avatar-placeholder"))
                }
            })
        
        nameView.font = UIFont.robotoOfSize(15, withType: .Medium)
        nameView.textColor = .whiteColor()
        nameView.rac_text <~ viewModel.name
        view.addSubview(nameView)
        
        userNameView.font = UIFont.robotoOfSize(12, withType: .Light)
        userNameView.textColor = .whiteColor()
        userNameView.rac_text <~ viewModel.userName.producer |> map { "@\($0)" }
        view.addSubview(userNameView)
        
        bioView.numberOfLines = 2
        bioView.textAlignment = .Center
        bioView.font = UIFont.robotoOfSize(13, withType: .Light)
        bioView.textColor = .whiteColor()
        bioView.rac_text <~ viewModel.bio
        view.addSubview(bioView)
        
        followButtonView.backgroundColor = .whiteColor()
        followButtonView.layer.borderWidth = 1
        followButtonView.layer.borderColor = BaseColor.CGColor
        followButtonView.layer.cornerRadius = 5
        followButtonView.layer.masksToBounds = true
        followButtonView.setTitleColor(BaseColor, forState: .Normal)
        followButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Regular)
        viewModel.isFollowing.producer |>
            start(next: { isFollowing in
                let title = isFollowing ? "Unfollow" : "Follow"
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
        editProfileButtonView.setTitle("Edit profile", forState: .Normal)
        editProfileButtonView.setTitleColor(BaseColor, forState: .Normal)
        editProfileButtonView.titleLabel?.font = .robotoOfSize(15, withType: .Regular)
        editProfileButtonView.rac_command = RACCommand(signalBlock: { _ in
            return RACSignal.empty()
        })
        editProfileButtonView.hidden = !isMe
        view.addSubview(editProfileButtonView)
        
        followersHeadingView.text = "Followers"
        followersHeadingView.font = .robotoOfSize(11, withType: .Regular)
        followersHeadingView.textColor = .blackColor()
        view.addSubview(followersHeadingView)
        
        followersCountView.rac_text <~ viewModel.numberOfFollowers.producer |> map { "\($0)" }
        followersCountView.font = .robotoOfSize(13, withType: .Medium)
        followersCountView.textColor = .blackColor()
        view.addSubview(followersCountView)
        
        verticalLineView.backgroundColor = UIColor(0xe5e5e5)
        view.addSubview(verticalLineView)
        
        followingHeadingView.text = "Following"
        followingHeadingView.font = .robotoOfSize(11, withType: .Regular)
        followingHeadingView.textColor = .blackColor()
        view.addSubview(followingHeadingView)
        
        followingCountView.rac_text <~ viewModel.numberOfFollowings.producer |> map { "\($0)" }
        followingCountView.font = .robotoOfSize(13, withType: .Medium)
        followingCountView.textColor = .blackColor()
        view.addSubview(followingCountView)
        
        let optographTableViewController = ProfileTableViewController(userId: viewModel.id.value)
        addChildViewController(optographTableViewController)
        optographsView = optographTableViewController.view
        view.addSubview(optographsView)
        
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        avatarBackgroundImageView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Bottom)
        avatarBackgroundImageView.autoSetDimension(.Height, toSize: 213)
        
        avatarBackgroundBlurView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
        
        avatarImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view, withOffset: 39)
        avatarImageView.autoAlignAxisToSuperviewAxis(.Vertical)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 84, height: 84))
        
        nameView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 17)
        nameView.autoAlignAxisToSuperviewAxis(.Vertical)
        
        userNameView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: nameView, withOffset: -2)
        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: nameView, withOffset: 5)

        bioView.autoPinEdge(.Top, toEdge: .Bottom, ofView: nameView, withOffset: 5)
        bioView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        bioView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        
        followButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        followButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        followButtonView.autoSetDimensionsToSize(CGSize(width: 110, height: 31))
        
        logoutButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        logoutButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        logoutButtonView.autoSetDimensionsToSize(CGSize(width: 40, height: 31))
        
        editProfileButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        editProfileButtonView.autoPinEdge(.Right, toEdge: .Left, ofView: logoutButtonView, withOffset: -3)
        editProfileButtonView.autoSetDimensionsToSize(CGSize(width: 110, height: 31))
        
        followersHeadingView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        followersHeadingView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        
        followersCountView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: followButtonView)
        followersCountView.autoPinEdge(.Left, toEdge: .Left, ofView: followersHeadingView)
        
        verticalLineView.autoPinEdge(.Top, toEdge: .Top, ofView: followersHeadingView)
        verticalLineView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: followersCountView)
        verticalLineView.autoPinEdge(.Left, toEdge: .Right, ofView: followersHeadingView, withOffset: 12)
        verticalLineView.autoSetDimension(.Width, toSize: 1)
        
        followingHeadingView.autoPinEdge(.Top, toEdge: .Top, ofView: followersHeadingView)
        followingHeadingView.autoPinEdge(.Left, toEdge: .Right, ofView: verticalLineView, withOffset: 12)
        
        followingCountView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: followButtonView)
        followingCountView.autoPinEdge(.Left, toEdge: .Left, ofView: followingHeadingView)
        
        optographsView.autoPinEdge(.Top, toEdge: .Bottom, ofView: followButtonView, withOffset: 20)
        optographsView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Top)
        
        super.updateViewConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateNavbarAppear()
    }
    
    func logout() {
        let refreshAlert = UIAlertController(title: "You're about to log out...", message: "Really? Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Sign out", style: .Default, handler: { (action: UIAlertAction!) in
            NSNotificationCenter.defaultCenter().postNotificationName(NotificationKeys.Logout.rawValue, object: nil)
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { _ in return }))
        
        presentViewController(refreshAlert, animated: true, completion: nil)
    }
    
}

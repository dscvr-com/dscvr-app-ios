//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ProfileViewController: UIViewController {
    
    var viewModel: ProfileViewModel
    
    // subviews
    let avatarBackgroundImageView = UIImageView()
    var avatarBackgroundBlurView: UIVisualEffectView!
    let avatarImageView = UIImageView()
    let nameView = UILabel()
    let userNameView = UILabel()
    let bioView = UILabel()
    let followButtonView = UIButton()
    let followersHeadingView = UILabel()
    let followersCountView = UILabel()
    let verticalLineView = UIView()
    let followingHeadingView = UILabel()
    let followingCountView = UILabel()
    var optographsView: UIView!
    
    required init(userId: Int) {
        viewModel = ProfileViewModel(id: userId)
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
                    self.avatarImageView.sd_setImageWithURL(avatarUrl, placeholderImage: UIImage(named: "placeholder"))
                    self.avatarBackgroundImageView.sd_setImageWithURL(avatarUrl, placeholderImage: UIImage(named: "placeholder"))
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
        followButtonView.layer.borderWidth = 2
        followButtonView.layer.borderColor = baseColor().CGColor
        followButtonView.layer.cornerRadius = 5
        followButtonView.layer.masksToBounds = true
        followButtonView.setTitleColor(baseColor(), forState: .Normal)
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
        view.addSubview(followButtonView)
        
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
        
        let optographTableViewController = OptographTableViewController(source: "users/\(viewModel.id.value)/optographs", navController: navigationController)
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
        
        userNameView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: nameView, withOffset: -3)
        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: nameView, withOffset: 5)
        
        bioView.autoPinEdge(.Top, toEdge: .Bottom, ofView: nameView, withOffset: 5)
        bioView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        bioView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        
        followButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarBackgroundImageView, withOffset: 20)
        followButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        followButtonView.autoSetDimensionsToSize(CGSize(width: 110, height: 31))
        
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
    
}

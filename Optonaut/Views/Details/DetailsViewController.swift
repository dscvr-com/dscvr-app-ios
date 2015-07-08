//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import WebImage
import CoreMotion

class DetailsViewController: UIViewController {
    
    var viewModel: OptographViewModel
    
    // subviews
    let detailsImageView = UIImageView()
    let locationView = InsetLabel()
    let maximizeButtonView = UIButton()
    let avatarImageView = UIImageView()
    let nameView = UILabel()
    let userNameView = UILabel()
    let dateView = UILabel()
    let shareButtonView = UIButton()
    let likeButtonView = UIButton()
    let likeCountView = UILabel()
    let commentIconView = UILabel()
    let commentCountView = UILabel()
    let viewIconView = UILabel()
    let viewCountView = UILabel()
    let textView = KILabel()
    let lineView = UIView()
    
    let motionManager = CMMotionManager()
    
    var originalNavigationBarTranslucent: Bool!
    var originalNavigationBarShadowImage: UIImage!
    
    required init(viewModel: OptographViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        viewModel = OptographViewModel(optograph: Optograph())
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .whiteColor()
        
        navigationItem.title = ""
        
        if let detailsUrl = NSURL(string: viewModel.detailsUrl.value) {
            detailsImageView.sd_setImageWithURL(detailsUrl, placeholderImage: UIImage(named: "placeholder"))
        }
        view.addSubview(detailsImageView)
        
        locationView.font = UIFont.robotoOfSize(12, withType: .Regular)
        locationView.textColor = .whiteColor()
        locationView.backgroundColor = UIColor(0x0).alpha(0.4)
        locationView.edgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        locationView.rac_text <~ viewModel.location
        view.addSubview(locationView)
        
        maximizeButtonView.titleLabel?.font = UIFont.icomoonOfSize(30)
        maximizeButtonView.setTitle(String.icomoonWithName(.ResizeFullScreen), forState: .Normal)
        maximizeButtonView.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        maximizeButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.pushViewer()
            return RACSignal.empty()
        })
        view.addSubview(maximizeButtonView)
        
        if let avatarUrl = NSURL(string: viewModel.avatarUrl.value) {
            avatarImageView.sd_setImageWithURL(avatarUrl, placeholderImage: UIImage(named: "placeholder"))
        }
        avatarImageView.layer.cornerRadius = 15
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        view.addSubview(avatarImageView)
        
        nameView.font = UIFont.robotoOfSize(15, withType: .Medium)
        nameView.textColor = UIColor(0x4d4d4d)
        nameView.rac_text <~ viewModel.user
        nameView.userInteractionEnabled = true
        nameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        view.addSubview(nameView)
        
        userNameView.font = UIFont.robotoOfSize(12, withType: .Light)
        userNameView.textColor = UIColor(0xb3b3b3)
        userNameView.rac_text <~ viewModel.userName
        userNameView.userInteractionEnabled = true
        userNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        view.addSubview(userNameView)
        
        dateView.font = UIFont.robotoOfSize(12, withType: .Light)
        dateView.textColor = UIColor(0xb3b3b3)
        dateView.rac_text <~ viewModel.timeSinceCreated
        view.addSubview(dateView)
        
        shareButtonView.titleLabel?.font = UIFont.icomoonOfSize(20)
        shareButtonView.setTitle(String.icomoonWithName(.Share), forState: .Normal)
        shareButtonView.setTitleColor(UIColor(0xe6e6e6), forState: .Normal)
        shareButtonView.rac_command = RACCommand(signalBlock: { _ in
            // TODO adjust sharing feature
            let textToShare = "Check out this Optograph of \(self.viewModel.user.value)."
            
            if let myWebsite = NSURL(string: "http://www.optonaut.com")
            {
                let objectsToShare = [textToShare, myWebsite]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
                activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
                
                self.presentViewController(activityVC, animated: true, completion: nil)
            }
            return RACSignal.empty()
        })
        view.addSubview(shareButtonView)
        
        likeButtonView.titleLabel?.font = UIFont.icomoonOfSize(20)
        likeButtonView.setTitle(String.icomoonWithName(.HeartOutlined), forState: .Normal)
        likeButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.toggleLike()
            return RACSignal.empty()
        })
        viewModel.liked.producer
            |> map { $0 ? baseColor() : UIColor(0xe6e6e6) }
            |> start(next: { self.likeButtonView.setTitleColor($0, forState: .Normal)})
        view.addSubview(likeButtonView)
        
        likeCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        likeCountView.textColor = UIColor(0xb3b3b3)
        likeCountView.rac_text <~ viewModel.likeCount.producer |> map { "\($0) likes" }
        view.addSubview(likeCountView)
        
        commentIconView.font = UIFont.icomoonOfSize(20)
        commentIconView.text = String.icomoonWithName(.CommentOutlined)
        commentIconView.textColor = UIColor(0xe6e6e6)
        view.addSubview(commentIconView)
        
        commentCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        commentCountView.textColor = UIColor(0xb3b3b3)
        commentCountView.rac_text <~ viewModel.commentCount.producer |> map { "\($0) comments" }
        view.addSubview(commentCountView)
        
        viewIconView.font = UIFont.icomoonOfSize(20)
        viewIconView.text = String.icomoonWithName(.Eye)
        viewIconView.textColor = UIColor(0xe6e6e6)
        view.addSubview(viewIconView)
        
        viewCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        viewCountView.textColor = UIColor(0xb3b3b3)
        viewCountView.rac_text <~ viewModel.viewCount.producer |> map { "\($0) views" }
        view.addSubview(viewCountView)
        
        textView.numberOfLines = 0
        textView.tintColor = baseColor()
        textView.userInteractionEnabled = true
        textView.font = UIFont.robotoOfSize(13, withType: .Light)
        textView.textColor = UIColor(0x4d4d4d)
        textView.rac_text <~ viewModel.text
        textView.userHandleLinkTapHandler = { label, handle, range in
            let profileViewController = ProfileViewController(userId: self.viewModel.userId.value)
            self.navigationController?.pushViewController(profileViewController, animated: true)
        }
        textView.hashtagLinkTapHandler = { label, hashtag, range in
            let hashtagTableViewController = HashtagTableViewController()
            self.navigationController?.pushViewController(hashtagTableViewController, animated: true)
        }
        view.addSubview(textView)
        
        lineView.backgroundColor = UIColor(0xe5e5e5)
        view.addSubview(lineView)
        
        motionManager.accelerometerUpdateInterval = 0.3
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        originalNavigationBarTranslucent = navigationController?.navigationBar.translucent
        originalNavigationBarShadowImage = navigationController?.navigationBar.shadowImage
        
        navigationController?.navigationBar.translucent = true
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { accelerometerData, error in
            if accelerometerData!.acceleration.x >= 0.75 {
                self.motionManager.stopAccelerometerUpdates()
                self.navigationController?.pushViewController(SphereViewController(), animated: false)
            } else if accelerometerData!.acceleration.x <= -0.75 {
                self.motionManager.stopAccelerometerUpdates()
                self.navigationController?.pushViewController(SphereViewController(), animated: false)
            }
        })
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            navigationController?.navigationBar.translucent = originalNavigationBarTranslucent
            navigationController?.navigationBar.shadowImage = originalNavigationBarShadowImage
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.motionManager.stopAccelerometerUpdates()
    }
    
    override func updateViewConstraints() {
        detailsImageView.autoPinEdge(.Top, toEdge: .Top, ofView: view)
        detailsImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: view)
        detailsImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: view, withMultiplier: 0.84)
        
        locationView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: detailsImageView, withOffset: -13)
        locationView.autoPinEdge(.Left, toEdge: .Left, ofView: detailsImageView, withOffset: 19)
        
        maximizeButtonView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: detailsImageView, withOffset: -8)
        maximizeButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: detailsImageView, withOffset: -19)
        
        avatarImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: detailsImageView, withOffset: 15)
        avatarImageView.autoPinEdge(.Left, toEdge: .Left, ofView: detailsImageView, withOffset: 19)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 30, height: 30))
        
        nameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: -2)
        nameView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        
        userNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView)
        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: nameView, withOffset: 4)
        
        dateView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: avatarImageView, withOffset: 2)
        dateView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        
        shareButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: detailsImageView, withOffset: 12)
        shareButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        
        likeButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 12)
        likeButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        
        likeCountView.autoPinEdge(.Top, toEdge: .Top, ofView: likeButtonView, withOffset: 8)
        likeCountView.autoPinEdge(.Left, toEdge: .Right, ofView: likeButtonView, withOffset: 5)
        
        commentIconView.autoPinEdge(.Top, toEdge: .Top, ofView: likeButtonView, withOffset: 4)
        commentIconView.autoPinEdge(.Left, toEdge: .Right, ofView: likeCountView, withOffset: 19)

        commentCountView.autoPinEdge(.Top, toEdge: .Top, ofView: likeCountView)
        commentCountView.autoPinEdge(.Left, toEdge: .Right, ofView: commentIconView, withOffset: 7)
        
        viewIconView.autoPinEdge(.Top, toEdge: .Top, ofView: likeButtonView, withOffset: 7)
        viewIconView.autoPinEdge(.Left, toEdge: .Right, ofView: commentCountView, withOffset: 19)

        viewCountView.autoPinEdge(.Top, toEdge: .Top, ofView: likeCountView)
        viewCountView.autoPinEdge(.Left, toEdge: .Right, ofView: viewIconView, withOffset: 7)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: likeButtonView, withOffset: 12)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 15)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -15)
        
        lineView.autoPinEdge(.Top, toEdge: .Bottom, ofView: textView, withOffset: 14)
        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        lineView.autoSetDimension(.Height, toSize: 1)
        
        super.updateViewConstraints()
    }
    
    func pushViewer() {
        navigationController?.pushViewController(SphereViewController(), animated: false)
    }
    
    func pushProfile() {
        let profileViewController = ProfileViewController(userId: viewModel.userId.value)
        navigationController?.pushViewController(profileViewController, animated: true)
    }
    
}

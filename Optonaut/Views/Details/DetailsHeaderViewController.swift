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
import ObjectMapper

class DetailsHeaderViewController: UIViewController {
    
    var viewModel: DetailsViewModel
    
    // subviews
    let detailsImageView = UIImageView()
    let locationView = InsetLabel()
    let maximizeButtonView = UIButton()
    let avatarImageView = UIImageView()
    let nameView = UILabel()
    let userNameView = UILabel()
    let dateView = UILabel()
    let shareButtonView = UIButton()
    let starButtonView = UIButton()
    let starCountView = UILabel()
    let commentIconView = UILabel()
    let commentCountView = UILabel()
    let viewIconView = UILabel()
    let viewsCountView = UILabel()
    let descriptionView = KILabel()
    let lineView = UIView()
    
    let motionManager = CMMotionManager()
    
    required init(optographId: Int) {
        self.viewModel = DetailsViewModel(optographId: optographId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        view.backgroundColor = .whiteColor()
        view.backgroundColor = UIColor.blueColor().alpha(0.5)
        
        navigationItem.title = ""
        
        viewModel.detailsUrl.producer
            .start(next: { url in
                if let detailsUrl = NSURL(string: url) {
                    self.detailsImageView.sd_setImageWithURL(detailsUrl, placeholderImage: UIImage(named: "optograph-details-placeholder"))
                }
            })
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
        
        viewModel.avatarUrl.producer
            .start(next: { url in
                if let avatarUrl = NSURL(string: url) {
                    self.avatarImageView.sd_setImageWithURL(avatarUrl, placeholderImage: UIImage(named: "avatar-placeholder"))
                }
            })
        avatarImageView.layer.cornerRadius = 15
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        view.addSubview(avatarImageView)
        
        nameView.font = UIFont.robotoOfSize(15, withType: .Medium)
        nameView.textColor = UIColor(0x4d4d4d)
        nameView.rac_text <~ viewModel.fullName
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
            let textToShare = "Check out this Optograph of \(self.viewModel.fullName.value)."
            
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
        
        starButtonView.titleLabel?.font = UIFont.icomoonOfSize(20)
        starButtonView.setTitle(String.icomoonWithName(.HeartOutlined), forState: .Normal)
        starButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.toggleLike()
            return RACSignal.empty()
        })
        viewModel.isStarred.producer
            .map { $0 ? BaseColor : UIColor(0xe6e6e6) }
            .start(next: { self.starButtonView.setTitleColor($0, forState: .Normal)})
        view.addSubview(starButtonView)
        
        starCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        starCountView.textColor = UIColor(0xb3b3b3)
        starCountView.rac_text <~ viewModel.starsCount.producer .map { "\($0) stars" }
        view.addSubview(starCountView)
        
        commentIconView.font = UIFont.icomoonOfSize(20)
        commentIconView.text = String.icomoonWithName(.CommentOutlined)
        commentIconView.textColor = UIColor(0xe6e6e6)
        view.addSubview(commentIconView)
        
        commentCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        commentCountView.textColor = UIColor(0xb3b3b3)
        commentCountView.rac_text <~ viewModel.commentsCount.producer .map { "\($0) comments" }
        view.addSubview(commentCountView)
        
        viewIconView.font = UIFont.icomoonOfSize(20)
        viewIconView.text = String.icomoonWithName(.Eye)
        viewIconView.textColor = UIColor(0xe6e6e6)
        view.addSubview(viewIconView)
        
        viewsCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        viewsCountView.textColor = UIColor(0xb3b3b3)
        viewsCountView.rac_text <~ viewModel.viewsCount.producer .map { "\($0) views" }
        view.addSubview(viewsCountView)
        
        descriptionView.numberOfLines = 0
        descriptionView.tintColor = BaseColor
        descriptionView.userInteractionEnabled = true
        descriptionView.font = UIFont.robotoOfSize(13, withType: .Light)
        descriptionView.textColor = UIColor(0x4d4d4d)
        descriptionView.rac_text <~ viewModel.description
        descriptionView.userHandleLinkTapHandler = { label, handle, range in
            let userName = handle.stringByReplacingOccurrencesOfString("@", withString: "")
            Api.get("persons/user-name/\(userName)", authorized: true)
                .start(next: { json in
                    let person = Mapper<Person>().map(json)!
                    self.navigationController?.pushViewController(ProfileContainerViewController(personId: person.id), animated: true)
                })
        }
        descriptionView.hashtagLinkTapHandler = { label, hashtag, range in
            self.navigationController?.pushViewController(HashtagTableViewController(hashtag: hashtag), animated: true)
        }
        view.addSubview(descriptionView)
        
        lineView.backgroundColor = UIColor(0xe5e5e5)
        view.addSubview(lineView)
        
        motionManager.accelerometerUpdateInterval = 0.3
        
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { accelerometerData, error in
            if let accelerometerData = accelerometerData {
                let x = accelerometerData.acceleration.x
                let y = accelerometerData.acceleration.y
                if abs(x) > abs(y) + 0.5 {
                    self.motionManager.stopAccelerometerUpdates()
                    let orientation: UIInterfaceOrientation = x > 0 ? .LandscapeLeft : .LandscapeRight
                    self.pushViewer(orientation)
                }
            }
        })
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
        
        starButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 12)
        starButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        
        starCountView.autoPinEdge(.Top, toEdge: .Top, ofView: starButtonView, withOffset: 8)
        starCountView.autoPinEdge(.Left, toEdge: .Right, ofView: starButtonView, withOffset: 5)
        
        commentIconView.autoPinEdge(.Top, toEdge: .Top, ofView: starButtonView, withOffset: 4)
        commentIconView.autoPinEdge(.Left, toEdge: .Right, ofView: starCountView, withOffset: 19)

        commentCountView.autoPinEdge(.Top, toEdge: .Top, ofView: starCountView)
        commentCountView.autoPinEdge(.Left, toEdge: .Right, ofView: commentIconView, withOffset: 7)
        
        viewIconView.autoPinEdge(.Top, toEdge: .Top, ofView: starButtonView, withOffset: 7)
        viewIconView.autoPinEdge(.Left, toEdge: .Right, ofView: commentCountView, withOffset: 19)

        viewsCountView.autoPinEdge(.Top, toEdge: .Top, ofView: starCountView)
        viewsCountView.autoPinEdge(.Left, toEdge: .Right, ofView: viewIconView, withOffset: 7)
        
        descriptionView.autoPinEdge(.Top, toEdge: .Bottom, ofView: starButtonView, withOffset: 12)
        descriptionView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 15)
        descriptionView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -15)
        
        lineView.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionView, withOffset: 14)
        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: view, withOffset: 19)
        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: view, withOffset: -19)
        lineView.autoSetDimension(.Height, toSize: 1)
        
        super.updateViewConstraints()
    }
    
    func pushViewer(orientation: UIInterfaceOrientation = .LandscapeLeft) {
        navigationController?.pushViewController(ViewerViewController(orientation: orientation), animated: false)
        viewModel.increaseViewsCount()
    }
    
    func pushProfile() {
        let profileContainerViewController = ProfileContainerViewController(personId: viewModel.personId.value)
        navigationController?.pushViewController(profileContainerViewController, animated: true)
    }
    
}

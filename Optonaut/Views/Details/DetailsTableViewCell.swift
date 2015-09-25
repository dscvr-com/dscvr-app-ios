//
//  ViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ActiveLabel

class DetailsTableViewCell: UITableViewCell {
    
    weak var viewModel: DetailsViewModel!
    weak var navigationController: NavigationController?
    
    // subviews
    private let wrapperView = UIView()
    private let barView = UIView()
    private let dateView = UILabel()
    private let starButtonView = UIButton()
    private let starsCountView = UILabel()
    private let previewImageView = PlaceholderImageView()
    private let locationView = UILabel()
    private let displayNameView = UILabel()
    private let avatarImageView = PlaceholderImageView()
    private let textView = ActiveLabel()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .blackColor()
        
        wrapperView.layer.cornerRadius = 6
        wrapperView.clipsToBounds = true
        wrapperView.backgroundColor = .whiteColor()
        contentView.addSubview(wrapperView)
        
        previewImageView.placeholderImage = UIImage(named: "optograph-placeholder")!
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
        wrapperView.addSubview(previewImageView)
        
        wrapperView.addSubview(barView)
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 15
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        barView.addSubview(avatarImageView)
        
        starButtonView.titleLabel?.font = UIFont.iconOfSize(17)
        starButtonView.setTitle(String.iconWithName(.Heart), forState: .Normal)
        starButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleStar"))
        barView.addSubview(starButtonView)
        
        starsCountView.font = UIFont.robotoOfSize(12, withType: .SemiBold)
        starsCountView.textColor = .Grey
        barView.addSubview(starsCountView)
        
        displayNameView.font = UIFont.robotoOfSize(12, withType: .SemiBold)
        displayNameView.textColor = .Grey
        displayNameView.textAlignment = .Right
        displayNameView.userInteractionEnabled = true
        displayNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        barView.addSubview(displayNameView)
        
        dateView.font = UIFont.robotoOfSize(10.2, withType: .Regular)
        dateView.textColor = .Grey
        dateView.textAlignment = .Right
        barView.addSubview(dateView)
        
        locationView.font = UIFont.robotoOfSize(14, withType: .SemiBold)
        locationView.textColor = .DarkGrey
        barView.addSubview(locationView)
        
//        previewImageView.placeholderImage = UIImage(named: "optograph-details-placeholder")!
//        previewImageView.contentMode = .ScaleAspectFill
//        previewImageView.clipsToBounds = true
//        previewImageView.userInteractionEnabled = true
//        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushViewer"))
//        contentView.addSubview(previewImageView)
        
//        locationView.font = UIFont.robotoOfSize(12, withType: .Regular)
//        locationView.textColor = .whiteColor()
//        locationView.backgroundColor = UIColor(0x0).alpha(0.4)
//        contentView.addSubview(locationView)
        
//        progressView.progressViewStyle = UIProgressViewStyle.Bar
//        progressView.progressTintColor = UIColor.Accent
//        contentView.addSubview(progressView)
        
//        actionButtonView.titleLabel?.font = UIFont.icomoonOfSize(20)
//        actionButtonView.setTitle(String.icomoonWithName(.DotsVertical), forState: .Normal)
//        actionButtonView.setTitleColor(UIColor(0xe6e6e6), forState: .Normal)
//        actionButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showActions"))
//        contentView.addSubview(actionButtonView)
        
        textView.numberOfLines = 0
        textView.userInteractionEnabled = true
        textView.font = UIFont.robotoOfSize(13, withType: .Regular)
        textView.textColor = .DarkGrey
        textView.mentionEnabled = false
        textView.hashtagColor = .Accent
        textView.URLEnabled = false
        wrapperView.addSubview(textView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        wrapperView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        wrapperView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView)
        wrapperView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView)
        wrapperView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: contentView, withOffset: -20)
        
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: wrapperView)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: contentView, withMultiplier: 7 / 8)
        
        barView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView)
        barView.autoPinEdge(.Left, toEdge: .Left, ofView: wrapperView)
        barView.autoPinEdge(.Right, toEdge: .Right, ofView: wrapperView)
        barView.autoSetDimension(.Height, toSize: 42)
        
        starButtonView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView)
        starButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: barView, withOffset: 15) // 4pt extra for heart border
        
        starsCountView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView)
        starsCountView.autoPinEdge(.Left, toEdge: .Right, ofView: starButtonView, withOffset: 3)
        
        locationView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView)
        locationView.autoAlignAxis(.Vertical, toSameAxisOfView: barView)
        
        avatarImageView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView)
        avatarImageView.autoPinEdge(.Right, toEdge: .Right, ofView: barView, withOffset: -7)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 29, height: 29))
        
        displayNameView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView, withOffset: -6)
        displayNameView.autoPinEdge(.Right, toEdge: .Left, ofView: avatarImageView, withOffset: -7)
        
        dateView.autoAlignAxis(.Horizontal, toSameAxisOfView: barView, withOffset: 6)
        dateView.autoPinEdge(.Right, toEdge: .Left, ofView: avatarImageView, withOffset: -7)
        
        textView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: wrapperView, withOffset: -18)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: wrapperView, withOffset: 18)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: wrapperView, withOffset: -18)
        
//        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
//        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
//        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: contentView, withMultiplier: 7/8)
//        
//        locationView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView, withOffset: -13)
//        locationView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
//        
//        avatarImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 15)
//        avatarImageView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
//        avatarImageView.autoSetDimensionsToSize(CGSize(width: 30, height: 30))
//        
//        progressView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView)
//        progressView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
//        
//        displayNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: -2)
//        displayNameView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
//        
//        userNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView)
//        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: displayNameView, withOffset: 4)
//        
//        dateView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: avatarImageView, withOffset: 2)
//        dateView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
//        
//        actionButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 12)
//        actionButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
//        
//        starButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 12)
//        starButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
//        
//        starCountView.autoPinEdge(.Top, toEdge: .Top, ofView: starButtonView, withOffset: 8)
//        starCountView.autoPinEdge(.Left, toEdge: .Right, ofView: starButtonView, withOffset: 5)
//        
//        commentIconView.autoPinEdge(.Top, toEdge: .Top, ofView: starButtonView, withOffset: 4)
//        commentIconView.autoPinEdge(.Left, toEdge: .Right, ofView: starCountView, withOffset: 19)
//
//        commentCountView.autoPinEdge(.Top, toEdge: .Top, ofView: starCountView)
//        commentCountView.autoPinEdge(.Left, toEdge: .Right, ofView: commentIconView, withOffset: 7)
//        
//        viewIconView.autoPinEdge(.Top, toEdge: .Top, ofView: starButtonView, withOffset: 7)
//        viewIconView.autoPinEdge(.Left, toEdge: .Right, ofView: commentCountView, withOffset: 19)
//
//        viewsCountView.autoPinEdge(.Top, toEdge: .Top, ofView: starCountView)
//        viewsCountView.autoPinEdge(.Left, toEdge: .Right, ofView: viewIconView, withOffset: 7)
//        
//        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: starButtonView, withOffset: 12)
//        textView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 15)
//        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -15)
//        
//        lineView.autoPinEdge(.Top, toEdge: .Bottom, ofView: textView, withOffset: 14)
//        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
//        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
//        lineView.autoSetDimension(.Height, toSize: 1)
        
        super.updateConstraints()
    }
    
    func bindViewModel() {
        previewImageView.rac_url <~ viewModel.previewImageUrl
        
        locationView.rac_text <~ viewModel.location.producer.map { $0.firstWord ?? "" } // TODO remove firstWord
        
//        progressView.rac_hidden <~ viewModel.downloadProgress.producer.observeOn(QueueScheduler.mainQueueScheduler).map { $0 == 1 }
        
//        viewModel.downloadProgress.producer
//            .startOn(QueueScheduler(queue: dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)))
//            .observeOn(UIScheduler())
//            .startWithNext { progress in
//                self.progressView.setProgress(progress, animated: true)
//            }
        
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        
        displayNameView.rac_text <~ viewModel.displayName
        
        dateView.rac_text <~ viewModel.timeSinceCreated
        
        starButtonView.rac_titleColor <~ viewModel.isStarred.producer.map { $0 ? UIColor.Accent : UIColor(0xe6e6e6) }
        
        starsCountView.rac_text <~ viewModel.starsCount.producer.map { "\($0)" }
        
//        commentCountView.rac_text <~ viewModel.commentsCount.producer.map { "\($0) comments" }
//        
//        viewsCountView.rac_text <~ viewModel.viewsCount.producer.map { "\($0) views" }
        
        textView.rac_text <~ viewModel.text
        textView.handleHashtagTap { [weak self] hashtag in
            self?.navigationController?.pushViewController(HashtagTableViewController(hashtag: hashtag), animated: true)
        }
        textView.mentionEnabled = false
    }
    
    func showActions() {
        let actionAlert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        if SessionService.sessionData?.id == viewModel.optograph.person.id {
            actionAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { _ in
                self.viewModel.delete().startWithCompleted {
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }))
        }
        
        if !viewModel.isPublished.value {
            actionAlert.addAction(UIAlertAction(title: "Publish", style: .Default, handler: { _ in
                self.viewModel.publish()
            }))
        }
        
        actionAlert.addAction(UIAlertAction(title: "Share", style: .Default, handler: { _ in
            // TODO adjust sharing feature
            if let myWebsite = NSURL(string: "http://share.optonaut.co/\(self.viewModel.optograph.id)") {
                let textToShare = "Check out this Optograph of \(self.viewModel.displayName.value): \(self.viewModel.text.value)"
                let objectsToShare = [textToShare, myWebsite]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
                activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
                
                self.navigationController?.presentViewController(activityVC, animated: true, completion: nil)
            }
        }))
        
        actionAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { _ in return }))
        
        navigationController?.presentViewController(actionAlert, animated: true, completion: nil)
    }
    
    func toggleStar() {
        viewModel.toggleLike()
    }
    
    func pushProfile() {
        let profileContainerViewController = ProfileTableViewController(personId: viewModel.personId.value)
        navigationController?.pushViewController(profileContainerViewController, animated: true)
    }
    
    func pushViewer() {
        if viewModel.downloadProgress.value == 1 {
            navigationController?.pushViewController(ViewerViewController(orientation: .LandscapeLeft, optograph: viewModel.optograph), animated: false)
            viewModel.increaseViewsCount()
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
}
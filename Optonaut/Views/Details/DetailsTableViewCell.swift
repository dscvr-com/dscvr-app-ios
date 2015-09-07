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
    private let previewImageView = UIImageView()
    private let locationView = InsetLabel()
    private let avatarImageView = UIImageView()
    private let progressView = UIProgressView()
    private let fullNameView = UILabel()
    private let userNameView = UILabel()
    private let dateView = UILabel()
    private let shareButtonView = UIButton()
    private let publishButtonView = UIButton()
    private let publishingIndicatorView = UIActivityIndicatorView()
    private let starButtonView = UIButton()
    private let starCountView = UILabel()
    private let commentIconView = UILabel()
    private let commentCountView = UILabel()
    private let viewIconView = UILabel()
    private let viewsCountView = UILabel()
    private let textView = ActiveLabel()
    private let lineView = UIView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushViewer"))
        contentView.addSubview(previewImageView)
        
        locationView.font = UIFont.robotoOfSize(12, withType: .Regular)
        locationView.textColor = .whiteColor()
        locationView.backgroundColor = UIColor(0x0).alpha(0.4)
        locationView.edgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        contentView.addSubview(locationView)
        
        progressView.progressViewStyle = UIProgressViewStyle.Bar
        progressView.progressTintColor = BaseColor
        contentView.addSubview(progressView)
        
        avatarImageView.layer.cornerRadius = 15
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(avatarImageView)
        
        fullNameView.font = UIFont.robotoOfSize(15, withType: .Medium)
        fullNameView.textColor = UIColor(0x4d4d4d)
        fullNameView.userInteractionEnabled = true
        fullNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(fullNameView)
        
        userNameView.font = UIFont.robotoOfSize(12, withType: .Light)
        userNameView.textColor = UIColor(0xb3b3b3)
        userNameView.userInteractionEnabled = true
        userNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(userNameView)
        
        dateView.font = UIFont.robotoOfSize(12, withType: .Light)
        dateView.textColor = UIColor(0xb3b3b3)
        contentView.addSubview(dateView)
        
        shareButtonView.titleLabel?.font = UIFont.icomoonOfSize(20)
        shareButtonView.setTitle(String.icomoonWithName(.Share), forState: .Normal)
        shareButtonView.setTitleColor(UIColor(0xe6e6e6), forState: .Normal)
        contentView.addSubview(shareButtonView)
        
        publishButtonView.titleLabel?.font = UIFont.icomoonOfSize(20)
        publishButtonView.setTitle(String.icomoonWithName(.Retry), forState: .Normal)
        publishButtonView.setTitleColor(BaseColor, forState: .Normal)
        contentView.addSubview(publishButtonView)
        
        publishingIndicatorView.hidesWhenStopped = true
        publishingIndicatorView.activityIndicatorViewStyle = .Gray
        contentView.addSubview(publishingIndicatorView)
        
        starButtonView.titleLabel?.font = UIFont.icomoonOfSize(20)
        starButtonView.setTitle(String.icomoonWithName(.HeartOutlined), forState: .Normal)
        contentView.addSubview(starButtonView)
        
        starCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        starCountView.textColor = UIColor(0xb3b3b3)
        contentView.addSubview(starCountView)
        
        commentIconView.font = UIFont.icomoonOfSize(20)
        commentIconView.text = String.icomoonWithName(.CommentOutlined)
        commentIconView.textColor = UIColor(0xe6e6e6)
        contentView.addSubview(commentIconView)
        
        commentCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        commentCountView.textColor = UIColor(0xb3b3b3)
        contentView.addSubview(commentCountView)
        
        viewIconView.font = UIFont.icomoonOfSize(20)
        viewIconView.text = String.icomoonWithName(.Eye)
        viewIconView.textColor = UIColor(0xe6e6e6)
        contentView.addSubview(viewIconView)
        
        viewsCountView.font = UIFont.robotoOfSize(12, withType: .Light)
        viewsCountView.textColor = UIColor(0xb3b3b3)
        contentView.addSubview(viewsCountView)
        
        textView.numberOfLines = 0
        textView.userInteractionEnabled = true
        textView.font = UIFont.robotoOfSize(13, withType: .Light)
        textView.textColor = UIColor(0x4d4d4d)
        textView.mentionColor = BaseColor
        textView.hashtagColor = BaseColor
        textView.URLEnabled = false
        contentView.addSubview(textView)
        
        lineView.backgroundColor = UIColor(0xe5e5e5)
        contentView.addSubview(lineView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        previewImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: contentView, withMultiplier: 0.84)
        
        locationView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView, withOffset: -13)
        locationView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
        
        avatarImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 15)
        avatarImageView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 30, height: 30))
        
        progressView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView)
        progressView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        
        fullNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: -2)
        fullNameView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        
        userNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView)
        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: fullNameView, withOffset: 4)
        
        dateView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: avatarImageView, withOffset: 2)
        dateView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        
        shareButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 12)
        shareButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        
        publishButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 12)
        publishButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        
        publishingIndicatorView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 16)
        publishingIndicatorView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -23)
        
        starButtonView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 12)
        starButtonView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        
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
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: starButtonView, withOffset: 12)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 15)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -15)
        
        lineView.autoPinEdge(.Top, toEdge: .Bottom, ofView: textView, withOffset: 14)
        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        lineView.autoSetDimension(.Height, toSize: 1)
        
        super.updateConstraints()
    }
    
    func bindViewModel() {
        previewImageView.rac_image <~ viewModel.previewImage
        
        locationView.rac_text <~ viewModel.location
        
        progressView.rac_hidden <~ viewModel.downloadProgress.producer.observeOn(QueueScheduler.mainQueueScheduler).map { $0 == 1 }
        
        viewModel.downloadProgress.producer
            .startOn(QueueScheduler(queue: dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)))
            .observeOn(UIScheduler())
            .start(next: { progress in
                self.progressView.setProgress(progress, animated: true)
            })
        
        avatarImageView.rac_image <~ viewModel.avatarImage
        
        fullNameView.rac_text <~ viewModel.fullName
        
        userNameView.rac_text <~ viewModel.userName
        
        dateView.rac_text <~ viewModel.timeSinceCreated
        
        shareButtonView.rac_hidden <~ viewModel.isPublished.producer.map { !$0 }
        shareButtonView.rac_command = RACCommand(signalBlock: { _ in
            // TODO adjust sharing feature
            let textToShare = "Check out this Optograph of \(self.viewModel.fullName.value)."
            
            if let myWebsite = NSURL(string: "http://www.optonaut.com")
            {
                let objectsToShare = [textToShare, myWebsite]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
                activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
                
                self.navigationController?.presentViewController(activityVC, animated: true, completion: nil)
            }
            return RACSignal.empty()
        })
        
        publishButtonView.rac_hidden <~ viewModel.isPublished.producer.combineLatestWith(viewModel.isPublishing.producer).map { $0 || $1 }
        publishButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.publish()
            return RACSignal.empty()
        })
        
        
        publishingIndicatorView.rac_animating <~ viewModel.isPublishing
        
        starButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.toggleLike()
            return RACSignal.empty()
        })
        
        viewModel.isStarred.producer
            .map { $0 ? BaseColor : UIColor(0xe6e6e6) }
            .start(next: { self.starButtonView.setTitleColor($0, forState: .Normal)})
        
        starCountView.rac_text <~ viewModel.starsCount.producer .map { "\($0) stars" }
        
        commentCountView.rac_text <~ viewModel.commentsCount.producer .map { "\($0) comments" }
        
        viewsCountView.rac_text <~ viewModel.viewsCount.producer .map { "\($0) views" }
        
        textView.rac_text <~ viewModel.text
        textView.handleHashtagTap { hashtag in
            self.navigationController?.pushViewController(HashtagTableViewController(hashtag: hashtag), animated: true)
        }
        textView.handleMentionTap { userName in
            ApiService<Person>.get("persons/user-name/\(userName)")
                .start(next: { person in
                    self.navigationController?.pushViewController(ProfileContainerViewController(personId: person.id), animated: true)
                })
        }
    }
    
    func pushProfile() {
        let profileContainerViewController = ProfileContainerViewController(personId: viewModel.personId.value)
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

//
//  OptographTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/21/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa
import WebImage
import ObjectMapper

class OptographTableViewCell: UITableViewCell {
    
    var navigationController: UINavigationController?
    var viewModel: OptographViewModel!
    
    // subviews
    let avatarImageView = UIImageView()
    let nameView = UILabel()
    let userNameView = UILabel()
    let dateView = UILabel()
    let likeButtonView = UIButton()
    let previewImageView = UIImageView()
    let locationView = InsetLabel()
    let textView = KILabel()
    let lineView = UIView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        avatarImageView.layer.cornerRadius = 15
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(avatarImageView)
        
        nameView.font = UIFont.robotoOfSize(15, withType: .Medium)
        nameView.textColor = UIColor(0x4d4d4d)
        nameView.userInteractionEnabled = true
        nameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(nameView)
        
        userNameView.font = UIFont.robotoOfSize(12, withType: .Light)
        userNameView.textColor = UIColor(0xb3b3b3)
        userNameView.userInteractionEnabled = true
        userNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(userNameView)
        
        dateView.font = UIFont.robotoOfSize(12, withType: .Light)
        dateView.textColor = UIColor(0xb3b3b3)
        contentView.addSubview(dateView)
        
        likeButtonView.titleLabel?.font = UIFont.icomoonOfSize(24)
        likeButtonView.setTitle(String.icomoonWithName(.HeartOutlined), forState: .Normal)
        contentView.addSubview(likeButtonView)
        
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
        contentView.addSubview(previewImageView)
        
        locationView.font = UIFont.robotoOfSize(12, withType: .Regular)
        locationView.textColor = .whiteColor()
        locationView.backgroundColor = UIColor(0x0).alpha(0.4)
        locationView.edgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        contentView.addSubview(locationView)
        
        textView.numberOfLines = 0
        textView.tintColor = BaseColor
        textView.userInteractionEnabled = true
        textView.font = UIFont.robotoOfSize(13, withType: .Light)
        textView.textColor = UIColor(0x4d4d4d)
        contentView.addSubview(textView)
        
        lineView.backgroundColor = UIColor(0xe5e5e5)
        contentView.addSubview(lineView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        avatarImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 15)
        avatarImageView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 30, height: 30))
        
        nameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: -2)
        nameView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        
        userNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView)
        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: nameView, withOffset: 4)
        
        dateView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: avatarImageView, withOffset: 2)
        dateView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        
        likeButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 12)
        likeButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -15) // 4pt extra for heart border
        
        previewImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: 14)
        previewImageView.autoMatchDimension(.Width, toDimension: .Width, ofView: contentView)
        previewImageView.autoMatchDimension(.Height, toDimension: .Width, ofView: contentView, withMultiplier: 0.45)
        
        locationView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: previewImageView, withOffset: -13)
        locationView.autoPinEdge(.Left, toEdge: .Left, ofView: previewImageView, withOffset: 19)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: previewImageView, withOffset: 16)
        textView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        
        lineView.autoPinEdge(.Top, toEdge: .Bottom, ofView: textView, withOffset: 14)
        lineView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        lineView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        lineView.autoSetDimension(.Height, toSize: 1)
        
        super.updateConstraints()
    }
    
    func bindViewModel(optograph: Optograph) {
        viewModel = OptographViewModel(optograph: optograph)
        
        if let previewUrl = NSURL(string: viewModel.previewUrl.value) {
            previewImageView.sd_setImageWithURL(previewUrl, placeholderImage: UIImage(named: "optograph-placeholder"))
        }
        
        if let avatarUrl = NSURL(string: viewModel.avatarUrl.value) {
            avatarImageView.sd_setImageWithURL(avatarUrl, placeholderImage: UIImage(named: "avatar-placeholder"))
        }
        
        nameView.rac_text <~ viewModel.user
        userNameView.rac_text <~ viewModel.userName
        locationView.rac_text <~ viewModel.location
        
        dateView.rac_text <~ viewModel.timeSinceCreated
        
        likeButtonView.rac_command = RACCommand(signalBlock: { _ in
            self.viewModel.toggleLike()
            return RACSignal.empty()
        })
        
        viewModel.liked.producer
            .map { $0 ? BaseColor : UIColor(0xe6e6e6) }
            .start(next: { self.likeButtonView.setTitleColor($0, forState: .Normal)})
        
        textView.rac_text <~ viewModel.text
        textView.userHandleLinkTapHandler = { label, handle, range in
            let userName = handle.stringByReplacingOccurrencesOfString("@", withString: "")
            Api.get("users/user-name/\(userName)", authorized: true)
                .start(next: { json in
                    let user = Mapper<User>().map(json)!
                    self.navigationController?.pushViewController(ProfileViewController(userId: user.id), animated: true)
                })
        }
        textView.hashtagLinkTapHandler = { label, hashtag, range in
            self.navigationController?.pushViewController(HashtagTableViewController(hashtag: hashtag), animated: true)
        }
    }
    
    func pushDetails() {
        let detailsViewController = DetailsViewController(optographId: viewModel.id.value)
        navigationController?.pushViewController(detailsViewController, animated: true)
    }
    
    func pushProfile() {
        let profileViewController = ProfileViewController(userId: viewModel.userId.value)
        navigationController?.pushViewController(profileViewController, animated: true)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}
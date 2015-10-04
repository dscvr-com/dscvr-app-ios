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
import HexColor
import ActiveLabel

class OptographTableViewCell: UITableViewCell {
    
    weak var navigationController: NavigationController?
    var viewModel: OptographViewModel!
    
    // subviews
    let avatarImageView = PlaceholderImageView()
    let displayNameView = UILabel()
    let userNameView = UILabel()
    let dateView = UILabel()
    let starButtonView = UIButton()
    let previewImageView = PlaceholderImageView()
    let locationView = InsetLabel()
    let textView = ActiveLabel()
    let lineView = UIView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .whiteColor()
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 15
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(avatarImageView)
        
        displayNameView.font = UIFont.robotoOfSize(15, withType: .Medium)
        displayNameView.textColor = UIColor(0x4d4d4d)
        displayNameView.userInteractionEnabled = true
        displayNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(displayNameView)
        
        userNameView.font = UIFont.robotoOfSize(12, withType: .Light)
        userNameView.textColor = UIColor(0xb3b3b3)
        userNameView.userInteractionEnabled = true
        userNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(userNameView)
        
        dateView.font = UIFont.robotoOfSize(12, withType: .Light)
        dateView.textColor = UIColor(0xb3b3b3)
        contentView.addSubview(dateView)
        
        starButtonView.titleLabel?.font = UIFont.icomoonOfSize(24)
        starButtonView.setTitle(String.icomoonWithName(.HeartOutlined), forState: .Normal)
        starButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggleStar"))
        contentView.addSubview(starButtonView)
        
        previewImageView.placeholderImage = UIImage(named: "optograph-placeholder")!
        previewImageView.contentMode = .ScaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.userInteractionEnabled = true
        previewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushDetails"))
        contentView.addSubview(previewImageView)
        
        locationView.font = UIFont.robotoOfSize(12, withType: .Regular)
        locationView.textColor = .whiteColor()
        locationView.backgroundColor = UIColor(0x0).alpha(0.4)
        locationView.edgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        contentView.addSubview(locationView)
        
        textView.numberOfLines = 0
        textView.mentionColor = UIColor.Accent
        textView.hashtagColor = UIColor.Accent
        textView.URLEnabled = false
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
        
        displayNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: -2)
        displayNameView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        
        userNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView)
        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: displayNameView, withOffset: 4)
        
        dateView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: avatarImageView, withOffset: 2)
        dateView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        
        starButtonView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 12)
        starButtonView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -15) // 4pt extra for heart border
        
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
        
        previewImageView.rac_url <~ viewModel.previewImageUrl
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        displayNameView.rac_text <~ viewModel.displayName
        userNameView.rac_text <~ viewModel.userName
        locationView.rac_text <~ viewModel.location
        dateView.rac_text <~ viewModel.timeSinceCreated
        starButtonView.rac_titleColor <~ viewModel.isStarred.producer.map { $0 ? UIColor.Accent : UIColor(0xe6e6e6) }
        
        textView.rac_text <~ viewModel.text
        textView.handleHashtagTap { [weak self] hashtag in
            self?.navigationController?.pushViewController(HashtagTableViewController(hashtag: hashtag), animated: true)
        }
        textView.handleMentionTap { userName in
            ApiService<Person>.get("persons/user-name/\(userName)").startWithNext { [weak self] person in
                self?.navigationController?.pushViewController(ProfileTableViewController(personId: person.id), animated: true)
            }
        }
    }
    
    func pushDetails() {
        navigationController?.pushViewController(DetailsTableViewController(optographId: viewModel.optograph.id), animated: true)
    }
    
    func pushProfile() {
        navigationController?.pushViewController(ProfileTableViewController(personId: viewModel.personId.value), animated: true)
    }
    
    func toggleStar() {
        viewModel.toggleLike()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}
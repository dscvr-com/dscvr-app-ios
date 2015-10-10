//
//  CommentTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 8/13/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import HexColor
import ActiveLabel

class CommentTableViewCell: UITableViewCell {
    
    weak var navigationController: NavigationController?
    var viewModel: CommentViewModel!
    
    // subviews
    private let textView = ActiveLabel()
    private let avatarImageView = PlaceholderImageView()
    private let displayNameView = UILabel()
    private let userNameView = UILabel()
    private let dateView = UILabel()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clearColor()
        
        textView.numberOfLines = 0
        textView.mentionColor = UIColor.Accent
        textView.hashtagColor = UIColor.Accent
        textView.URLEnabled = false
        textView.userInteractionEnabled = true
        textView.font = UIFont.robotoOfSize(13, withType: .Light)
        textView.textColor = .whiteColor()
        contentView.addSubview(textView)
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 15
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(avatarImageView)
        
        displayNameView.font = UIFont.robotoOfSize(15, withType: .Medium)
        displayNameView.textColor = .whiteColor()
        displayNameView.userInteractionEnabled = true
        displayNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(displayNameView)
        
        userNameView.font = UIFont.robotoOfSize(12, withType: .Light)
        userNameView.textColor = .whiteColor()
        userNameView.userInteractionEnabled = true
        userNameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(userNameView)
        
        dateView.font = UIFont.robotoOfSize(12, withType: .Light)
        dateView.textColor = .whiteColor()
        contentView.addSubview(dateView)
        
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
        
        dateView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 15)
        dateView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: displayNameView, withOffset: 3)
        textView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        
        super.updateConstraints()
    }
    
    func bindViewModel(comment: Comment) {
        viewModel = CommentViewModel(comment: comment)
        
        textView.rac_text <~ viewModel.text
        textView.handleHashtagTap { hashtag in
            self.navigationController?.pushViewController(HashtagTableViewController(hashtag: hashtag), animated: true)
        }
        textView.handleMentionTap { userName in
            ApiService<Person>.get("persons/user-name/\(userName)").startWithNext { person in
                self.navigationController?.pushViewController(ProfileTableViewController(personId: person.id), animated: true)
            }
        }
        
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        displayNameView.rac_text <~ viewModel.displayName
        userNameView.rac_text <~ viewModel.userName
        dateView.rac_text <~ viewModel.timeSinceCreated
    }
    
    func pushProfile() {
        navigationController?.pushViewController(ProfileTableViewController(personId: viewModel.personId.value), animated: true)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}
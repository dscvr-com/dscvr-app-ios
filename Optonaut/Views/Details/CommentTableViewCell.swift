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
    private let dateView = UILabel()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clearColor()
        
        textView.numberOfLines = 0
        textView.mentionColor = UIColor.Accent
        textView.hashtagColor = UIColor.Accent
        textView.URLEnabled = false
        textView.userInteractionEnabled = true
        textView.font = UIFont.textOfSize(13, withType: .Regular)
        textView.textColor = .whiteColor()
        contentView.addSubview(textView)
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(avatarImageView)
        
        dateView.font = UIFont.robotoOfSize(12, withType: .Light)
        dateView.textColor = .whiteColor()
        dateView.textAlignment = .Right
        contentView.addSubview(dateView)
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        avatarImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 5)
        avatarImageView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 40, height: 40))
        
        dateView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        dateView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        dateView.autoSetDimension(.Width, toSize: 30)
        
        if frame.height > 60 {
            textView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 3)
        } else {
            textView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        }
        textView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 20)
        textView.autoPinEdge(.Right, toEdge: .Left, ofView: dateView, withOffset: -20)
        
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
        dateView.rac_text <~ viewModel.timeSinceCreated
    }
    
    func pushProfile() {
        navigationController?.pushViewController(ProfileTableViewController(personId: viewModel.personId.value), animated: true)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}
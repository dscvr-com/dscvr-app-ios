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

class CommentTableViewCell: UITableViewCell {
    
    var navigationController: UINavigationController?
    var viewModel: CommentViewModel!
    
    // subviews
    private let textView = KILabel()
    private let avatarImageView = UIImageView()
    private let fullNameView = UILabel()
    private let userNameView = UILabel()
    private let dateView = UILabel()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textView.numberOfLines = 0
        textView.tintColor = BaseColor
        textView.userInteractionEnabled = true
        textView.font = UIFont.robotoOfSize(13, withType: .Light)
        textView.textColor = UIColor(0x4d4d4d)
        contentView.addSubview(textView)
        
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
        
        contentView.setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        avatarImageView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 15)
        avatarImageView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 19)
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 30, height: 30))
        
        fullNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView, withOffset: -2)
        fullNameView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        
        userNameView.autoPinEdge(.Top, toEdge: .Top, ofView: avatarImageView)
        userNameView.autoPinEdge(.Left, toEdge: .Right, ofView: fullNameView, withOffset: 4)
        
        dateView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 15)
        dateView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        
        textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: fullNameView, withOffset: 3)
        textView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 11)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -19)
        
        super.updateConstraints()
    }
    
    func bindViewModel(comment: Comment) {
        viewModel = CommentViewModel(comment: comment)
        
        textView.rac_text <~ viewModel.text
        avatarImageView.rac_image <~ viewModel.avatarImage
        fullNameView.rac_text <~ viewModel.fullName
        userNameView.rac_text <~ viewModel.userName
        dateView.rac_text <~ viewModel.timeSinceCreated
    }
    
    func pushProfile() {
        navigationController?.pushViewController(ProfileContainerViewController(personId: viewModel.personId.value), animated: true)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}
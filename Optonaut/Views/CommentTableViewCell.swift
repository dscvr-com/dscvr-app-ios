//
//  CommentTableViewCell.swift
//  Iam360
//
//  Created by robert john alkuino on 6/10/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import UIKit
import ReactiveCocoa
import HexColor

class CommentTableViewCell: UITableViewCell {
    weak var navigationController: NavigationController?
    var viewModel: CommentViewModel!
    
    // subviews
    private let textView = UILabel()
    private let avatarImageView = PlaceholderImageView()
    private let usernameView = UILabel()
    private let dateView = UILabel()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clearColor()
        
        textView.numberOfLines = 0
        textView.userInteractionEnabled = true
        textView.font = UIFont.textOfSize(13, withType: .Regular)
        textView.textColor =  UIColor.grayColor()
        textView.text = "Lorem ipsum is simply dummy text of the printing"
        contentView.addSubview(textView)
        
        usernameView.font = UIFont.textOfSize(15, withType: .Regular)
        usernameView.textColor =  UIColor(hex:0xffbc00)
        usernameView.text = "John Smith"
        contentView.addSubview(usernameView)
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        //avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        contentView.addSubview(avatarImageView)
        
        dateView.font = UIFont.robotoOfSize(12, withType: .Light)
        dateView.textColor = UIColor.grayColor()
        dateView.textAlignment = .Right
        dateView.text = "2d"
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
        
        //textView.rac_text <~ viewModel.text
        
        usernameView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView, withOffset: 20)
        usernameView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 20)
        
        textView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 20)
        textView.autoPinEdge(.Right, toEdge: .Left, ofView: dateView, withOffset: -20)
        
        super.updateConstraints()
    }
    
    func bindViewModel(comment: Comment) {
        viewModel = CommentViewModel(comment: comment)
        
        avatarImageView.rac_url <~ viewModel.avatarImageUrl
        dateView.rac_text <~ viewModel.timeSinceCreated
        textView.rac_text <~ viewModel.text
        usernameView.rac_text <~ viewModel.userName
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}

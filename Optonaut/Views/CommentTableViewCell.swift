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
    //private var causingPersonId:UUID = ""
    let eliteImageView = UIImageView()
    
    required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clearColor()
        
        textView.numberOfLines = 0
        textView.userInteractionEnabled = true
        textView.font = UIFont (name: "Avenir-Book", size: 15)
        textView.textColor =  UIColor.grayColor()
        contentView.addSubview(textView)
        
        usernameView.font = UIFont (name: "Avenir-Heavy", size: 17)
        usernameView.textColor =  UIColor(hex:0xFF5E00)
        contentView.addSubview(usernameView)
        
        avatarImageView.placeholderImage = UIImage(named: "avatar-placeholder")!
        avatarImageView.layer.cornerRadius = 25
        avatarImageView.clipsToBounds = true
        avatarImageView.userInteractionEnabled = true
        avatarImageView.layer.borderColor = UIColor(hex:0xFF5E00).CGColor
        avatarImageView.layer.borderWidth = 2.0
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CommentTableViewCell.pushProfile)))
        contentView.addSubview(avatarImageView)
        
        eliteImageView.image = UIImage(named: "elite_beta_icn")!
        contentView.addSubview(eliteImageView)
        
        dateView.font = UIFont (name: "Avenir-Book", size: 13)
        dateView.textColor = UIColor.grayColor()
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
        avatarImageView.autoSetDimensionsToSize(CGSize(width: 50, height: 50))
        
        dateView.autoAlignAxis(.Horizontal, toSameAxisOfView: avatarImageView)
        dateView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -20)
        dateView.autoSetDimension(.Width, toSize: 30)
        
        eliteImageView.autoPinEdge(.Left, toEdge: .Left, ofView: contentView, withOffset: 22)
        eliteImageView.autoPinEdge(.Top, toEdge: .Bottom, ofView: avatarImageView, withOffset: -8)
        let size = UIImage(named: "elite_beta_icn")!.size
        eliteImageView.autoSetDimensionsToSize(CGSize(width: size.width, height: size.height))

        usernameView.autoPinEdge(.Top, toEdge: .Top, ofView: contentView, withOffset: 10)
        usernameView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 20)
        
        //textView.autoPinEdge(.Top, toEdge: .Bottom, ofView: usernameView, withOffset: 10)
        textView.autoPinEdge(.Bottom, toEdge: .Bottom, ofView: contentView, withOffset: -10)
        textView.autoPinEdge(.Left, toEdge: .Right, ofView: avatarImageView, withOffset: 20)
        textView.autoPinEdge(.Right, toEdge: .Right, ofView: contentView, withOffset: -30)
        
        super.updateConstraints()
    }
    
    func bindViewModel(comment: Comment) {
        viewModel = CommentViewModel(comment: comment)
        
        viewModel.avatarImageUrl.producer.startWithNext {
            self.avatarImageView.kf_setImageWithURL(NSURL(string:$0)!)
        }
        
        dateView.rac_text <~ viewModel.timeSinceCreated
        textView.rac_text <~ viewModel.text
        usernameView.rac_text <~ viewModel.userName
    }
    
    func pushProfile() {
        let profilepage = ProfileCollectionViewController(personID: viewModel.personID.value)
        profilepage.isProfileVisit = true
        self.navigationController?.pushViewController(profilepage, animated: true)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {}
    override func setHighlighted(highlighted: Bool, animated: Bool) {}
    
}

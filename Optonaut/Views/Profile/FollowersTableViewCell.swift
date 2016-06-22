//
//  FollowersTableViewCell.swift
//  Iam360
//
//  Created by robert john alkuino on 6/22/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation

class FollowersTableViewCell: UITableViewCell {
    
    var userImage: UIImageView = UIImageView()
    var nameLabel: UILabel = UILabel()
    var followButton = UIButton()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.userImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 50.0, height: 50.0))
        self.userImage.center = CGPoint(x: userImage.frame.size.width/2.0 + 20.0, y: self.contentView.frame.height/2 + 15.0)
        self.userImage.backgroundColor = UIColor.lightGrayColor()
        self.userImage.layer.cornerRadius = self.userImage.frame.size.width/2
        self.userImage.layer.borderColor = UIColor(hex:0xffbc00).CGColor
        self.userImage.layer.borderWidth = 2.0
        self.userImage.clipsToBounds = true
        self.userImage.image = UIImage(named: "avatar-placeholder")!
        
        
        self.nameLabel = UILabel(frame: CGRect(x: self.userImage.frame.origin.x + self.userImage.frame.size.width + 10.0, y: self.userImage.frame.origin.y + 10.0, width: 100.0, height: 30.0))
        self.nameLabel.font = UIFont.systemFontOfSize(13.0, weight: UIFontWeightMedium)
        self.nameLabel.text = "Junjuners"
        self.nameLabel.textColor = UIColor.darkGrayColor()
        
        
        followButton.setBackgroundImage(UIImage(named: "follow_inactive"), forState: .Normal)
        let followButtonSize = UIImage(named: "follow_inactive")?.size
        followButton.frame = CGRect(x: contentView.frame.width-(followButtonSize?.width)!-20,y: (contentView.frame.height/2)+5,width: (followButtonSize?.width)!, height: (followButtonSize?.height)!)
        contentView.addSubview(followButton)
        //followButton.anchorToEdge(.Right, padding: 15, width: (followButtonSize?.width)!, height: (followButtonSize?.height)!)
        
        contentView.addSubview(userImage)
        contentView.addSubview(nameLabel)
    }
    
    required init(coder aDecoder: NSCoder){
        //Just Call Super
        super.init(coder: aDecoder)!
    }
}

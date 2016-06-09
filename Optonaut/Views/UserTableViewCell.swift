//
//  UserTableViewCell.swift
//  PhotoViewGallery
//
//  Created by Thadz on 07/06/2016.
//  Copyright © 2016 Brewed Concepts. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    
    var userImage: UIImageView = UIImageView()
    var nameLabel: UILabel = UILabel()
    var locationLabel: UILabel = UILabel()

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
        self.nameLabel.textColor = UIColor.darkGrayColor()
        
        self.locationLabel = UILabel(frame: CGRect(x: self.nameLabel.frame.origin.x, y: 0, width: 100.0, height: 20.0))
        self.locationLabel.font = UIFont.systemFontOfSize(10.0, weight: UIFontWeightLight)
        self.locationLabel.textColor = UIColor.grayColor()
        
        self.addSubview(userImage)
        self.addSubview(nameLabel)
        self.addSubview(locationLabel)
    }
    
    required init(coder aDecoder: NSCoder){
        //Just Call Super
        super.init(coder: aDecoder)!
    }
    
}

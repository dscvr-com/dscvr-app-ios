//
//  ActivityFollowTableViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 10/24/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import UIKit

class ActivityFollowTableViewCell: ActivityTableViewCell {
    
    required init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        causingImageView.userInteractionEnabled = true
        causingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "pushProfile"))
        
        contentView.setNeedsUpdateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
        super.updateConstraints()
    }
    
    override func update() {
        causingImageView.setImageWithURLString(activity.activityResourceFollow!.causingPerson.avatarAssetURL)
        
        super.update()
    }
    
    func pushProfile() {
        navigationController?.pushViewController(ProfileTableViewController(personID: activity.activityResourceFollow!.causingPerson.ID), animated: true)
    }
    
}